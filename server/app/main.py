import json
import os
import secrets
import time
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from .db import Base, engine, get_db
from .models import (
    ExerciseMember,
    Follow,
    ProgramMember,
    SharedExercise,
    SharedProgram,
    User,
)
from .security import create_token, decode_token, hash_password, verify_password


def _now_ms() -> int:
    return int(time.time() * 1000)

Base.metadata.create_all(bind=engine)


def _ensure_columns() -> None:
    """Lightweight migration: add columns introduced after the table was first
    created. create_all() never alters existing tables, so we add them by hand.
    Safe to run on every startup (no-op once the column exists)."""
    from sqlalchemy import inspect, text

    inspector = inspect(engine)
    try:
        cols = {c["name"] for c in inspector.get_columns("users")}
    except Exception:
        return
    if "last_login" not in cols:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE users ADD COLUMN last_login DATETIME"))


_ensure_columns()

# Accounts whose email is in this set get admin privileges (e.g. the Users
# directory in Settings). Configurable via the ADMIN_EMAILS env var (comma
# separated); defaults to the project owner.
ADMIN_EMAILS = {
    e.strip().lower()
    for e in os.environ.get("ADMIN_EMAILS", "andersonmourot@aol.com").split(",")
    if e.strip()
}

# Test/seed accounts created during development are hidden from the admin Users
# directory. Anything on the reserved example.com domain (RFC 2606, never a real
# user) is hidden automatically; HIDDEN_EMAILS may add specific extra addresses.
HIDDEN_EMAILS = {
    e.strip().lower()
    for e in os.environ.get("HIDDEN_EMAILS", "").split(",")
    if e.strip()
}


def _is_admin(user: "User") -> bool:
    return user.email.lower() in ADMIN_EMAILS


def _is_seed_account(email: str) -> bool:
    """Whether an account is a Devin-made test/seed account (hidden from admin)."""
    e = email.lower().strip()
    return e.endswith("@example.com") or e in HIDDEN_EMAILS


app = FastAPI(title="SMELLIS Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---- Schemas ----
class SignupBody(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    email: EmailStr
    password: str = Field(min_length=6, max_length=200)


class LoginBody(BaseModel):
    email: EmailStr
    password: str


class ChangePasswordBody(BaseModel):
    current_password: str = Field(min_length=1, max_length=200)
    new_password: str = Field(min_length=6, max_length=200)


class PublicUser(BaseModel):
    id: str
    name: str
    email: str
    is_admin: bool = False


class AuthResponse(BaseModel):
    token: str
    user: PublicUser


class DataBody(BaseModel):
    data: dict


class DiscoverUser(BaseModel):
    id: str
    name: str
    color: str
    following: bool
    program_count: int
    exercise_count: int = 0


class FollowUser(BaseModel):
    id: str
    name: str
    color: str
    program_count: int
    exercise_count: int = 0


class SharedUser(BaseModel):
    id: str
    name: str


class AdminUser(BaseModel):
    id: str
    name: str
    email: str
    created_at: str
    last_login: str


class SharedPrograms(BaseModel):
    user: SharedUser
    programs: list[dict]


class SharedExercises(BaseModel):
    user: SharedUser
    exercises: list[dict]


class ProgramBody(BaseModel):
    program: dict


class ExerciseBody(BaseModel):
    exercise: dict


class BatchBody(BaseModel):
    ids: list[str]


# ---- Helpers ----
def _public(user: User) -> PublicUser:
    return PublicUser(
        id=user.id, name=user.name, email=user.email, is_admin=_is_admin(user)
    )


def _custom_programs(user: User) -> list[dict]:
    """Extract a user's custom (shareable) programs from their data blob."""
    try:
        blob = json.loads(user.data or "{}")
    except json.JSONDecodeError:
        return []
    progs = blob.get("customPrograms")
    return progs if isinstance(progs, list) else []


def _shared_exercises(user: User) -> list[dict]:
    """Extract a user's custom exercises that are flagged as shareable."""
    try:
        blob = json.loads(user.data or "{}")
    except json.JSONDecodeError:
        return []
    exs = blob.get("customExercises")
    if not isinstance(exs, list):
        return []
    shared: list[dict] = []
    for e in exs:
        if isinstance(e, dict) and e.get("shared"):
            out = dict(e)
            out["ownerId"] = user.id
            out["ownerName"] = user.name
            shared.append(out)
    return shared


DEFAULT_THEME_COLOR = "#355e3b"


def _theme_color(user: User) -> str:
    """Read the user's chosen profile/theme color from their data blob."""
    try:
        blob = json.loads(user.data or "{}")
    except json.JSONDecodeError:
        return DEFAULT_THEME_COLOR
    color = blob.get("themeColor")
    return color if isinstance(color, str) and color else DEFAULT_THEME_COLOR


def _enrich(program: dict, sp: SharedProgram) -> dict:
    """Stamp the authoritative sharing metadata onto a program dict."""
    out = dict(program)
    out["id"] = sp.id
    out["ownerId"] = sp.owner_id
    out["ownerName"] = sp.owner_name
    out["collaborative"] = sp.collaborative
    out["version"] = sp.version
    return out


def _ensure_member(db: Session, program_id: str, user_id: str) -> None:
    exists = (
        db.query(ProgramMember)
        .filter(ProgramMember.program_id == program_id, ProgramMember.user_id == user_id)
        .first()
    )
    if not exists:
        db.add(ProgramMember(program_id=program_id, user_id=user_id))


def _publish_owned_programs(db: Session, owner: User) -> list[dict]:
    """Ensure every program in the owner's blob exists in the shared store, then
    return the canonical list of programs this user owns."""
    blob_progs = _custom_programs(owner)
    changed = False
    for p in blob_progs:
        pid = p.get("id")
        if not pid:
            continue
        sp = db.get(SharedProgram, pid)
        if sp is None:
            version = int(p.get("version") or _now_ms())
            sp = SharedProgram(
                id=pid,
                owner_id=owner.id,
                owner_name=owner.name,
                collaborative=bool(p.get("collaborative")),
                data=json.dumps(p),
                version=version,
                updated_by=owner.id,
            )
            sp.data = json.dumps(_enrich(p, sp))
            db.add(sp)
            _ensure_member(db, pid, owner.id)
            changed = True
    if changed:
        db.commit()
    owned = db.query(SharedProgram).filter(SharedProgram.owner_id == owner.id).all()
    return [json.loads(sp.data) for sp in owned]


def _enrich_exercise(exercise: dict, se: SharedExercise) -> dict:
    """Stamp the authoritative sharing metadata onto an exercise dict."""
    out = dict(exercise)
    out["id"] = se.id
    out["ownerId"] = se.owner_id
    out["ownerName"] = se.owner_name
    out["collaborative"] = se.collaborative
    out["version"] = se.version
    out["shared"] = True
    return out


def _ensure_exercise_member(db: Session, exercise_id: str, user_id: str) -> None:
    exists = (
        db.query(ExerciseMember)
        .filter(
            ExerciseMember.exercise_id == exercise_id,
            ExerciseMember.user_id == user_id,
        )
        .first()
    )
    if not exists:
        db.add(ExerciseMember(exercise_id=exercise_id, user_id=user_id))


def _publish_owned_exercises(db: Session, owner: User) -> list[dict]:
    """Ensure each shared exercise in the owner's blob exists in the canonical
    store, then return the canonical list of exercises this user owns."""
    changed = False
    for e in _shared_exercises(owner):
        eid = e.get("id")
        if not eid:
            continue
        se = db.get(SharedExercise, eid)
        if se is None:
            version = int(e.get("version") or _now_ms())
            se = SharedExercise(
                id=eid,
                owner_id=owner.id,
                owner_name=owner.name,
                collaborative=bool(e.get("collaborative")),
                data="{}",
                version=version,
                updated_by=owner.id,
            )
            se.data = json.dumps(_enrich_exercise(e, se))
            db.add(se)
            _ensure_exercise_member(db, eid, owner.id)
            changed = True
    if changed:
        db.commit()
    owned = db.query(SharedExercise).filter(SharedExercise.owner_id == owner.id).all()
    return [json.loads(se.data) for se in owned]


def current_user(
    x_auth_token: str | None = Header(default=None),
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> User:
    # Prefer X-Auth-Token so the Authorization header stays free for the
    # tunnel/proxy's HTTP basic auth. Fall back to a bearer token for
    # local dev and API clients.
    token: str | None = None
    if x_auth_token:
        token = x_auth_token.removeprefix("Bearer ").strip()
    elif authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Missing auth token")
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Account not found")
    return user


# ---- Routes ----
@app.get("/health")
def health():
    return {"ok": True}


@app.post("/auth/signup", response_model=AuthResponse)
def signup(body: SignupBody, db: Session = Depends(get_db)):
    email = body.email.lower().strip()
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=409, detail="An account with that email already exists.")
    user = User(
        id=secrets.token_hex(12),
        name=body.name.strip(),
        email=email,
        password_hash=hash_password(body.password),
        data="{}",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return AuthResponse(token=create_token(user.id), user=_public(user))


@app.post("/auth/login", response_model=AuthResponse)
def login(body: LoginBody, db: Session = Depends(get_db)):
    email = body.email.lower().strip()
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect email or password.")
    user.last_login = datetime.now(timezone.utc)
    db.add(user)
    db.commit()
    return AuthResponse(token=create_token(user.id), user=_public(user))


@app.post("/auth/password")
def change_password(
    body: ChangePasswordBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(body.current_password, user.password_hash):
        raise HTTPException(status_code=401, detail="Current password is incorrect.")
    if body.new_password == body.current_password:
        raise HTTPException(
            status_code=400, detail="New password must be different from the current one."
        )
    user.password_hash = hash_password(body.new_password)
    db.add(user)
    db.commit()
    return {"ok": True}


@app.get("/me", response_model=PublicUser)
def me(user: User = Depends(current_user)):
    return _public(user)


@app.get("/api/admin/users", response_model=list[AdminUser])
def admin_users(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    if not _is_admin(user):
        raise HTTPException(status_code=403, detail="Admin access required.")
    rows = db.query(User).order_by(User.created_at.asc()).all()
    return [
        AdminUser(
            id=u.id,
            name=u.name,
            email=u.email,
            created_at=(u.created_at.isoformat() if u.created_at else ""),
            last_login=(u.last_login.isoformat() if u.last_login else ""),
        )
        for u in rows
        if not _is_seed_account(u.email)
    ]


@app.get("/api/data")
def get_data(user: User = Depends(current_user)):
    try:
        return json.loads(user.data or "{}")
    except json.JSONDecodeError:
        return {}


@app.put("/api/data")
def put_data(
    body: DataBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    user.data = json.dumps(body.data)
    db.add(user)
    db.commit()
    return {"ok": True}


# ---- Social: search / follow / shared programs ----
@app.get("/api/users/search", response_model=list[DiscoverUser])
def search_users(
    q: str = "",
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    term = q.strip()
    if not term:
        return []
    like = f"%{term}%"
    rows = (
        db.query(User)
        .filter(User.id != user.id)
        .filter(User.name.ilike(like))
        .order_by(User.name)
        .limit(25)
        .all()
    )
    following_ids = {
        f.following_id for f in db.query(Follow).filter(Follow.follower_id == user.id).all()
    }
    return [
        DiscoverUser(
            id=u.id,
            name=u.name,
            color=_theme_color(u),
            following=u.id in following_ids,
            program_count=len(_custom_programs(u)),
            exercise_count=len(_shared_exercises(u)),
        )
        for u in rows
    ]


@app.post("/api/users/{user_id}/follow")
def follow_user(
    user_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    if user_id == user.id:
        raise HTTPException(status_code=400, detail="You cannot follow yourself.")
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found.")
    exists = (
        db.query(Follow)
        .filter(Follow.follower_id == user.id, Follow.following_id == user_id)
        .first()
    )
    if not exists:
        db.add(Follow(follower_id=user.id, following_id=user_id))
        db.commit()
    return {"ok": True, "following": True}


@app.delete("/api/users/{user_id}/follow")
def unfollow_user(
    user_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    db.query(Follow).filter(
        Follow.follower_id == user.id, Follow.following_id == user_id
    ).delete()
    db.commit()
    return {"ok": True, "following": False}


@app.get("/api/following", response_model=list[FollowUser])
def list_following(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    follows = (
        db.query(Follow)
        .filter(Follow.follower_id == user.id)
        .order_by(Follow.created_at.desc())
        .all()
    )
    out: list[FollowUser] = []
    for f in follows:
        u = db.get(User, f.following_id)
        if not u:
            continue
        out.append(
            FollowUser(
                id=u.id,
                name=u.name,
                color=_theme_color(u),
                program_count=len(_custom_programs(u)),
                exercise_count=len(_shared_exercises(u)),
            )
        )
    return out


@app.get("/api/users/{user_id}/programs", response_model=SharedPrograms)
def user_programs(
    user_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found.")
    return SharedPrograms(
        user=SharedUser(id=target.id, name=target.name),
        programs=_publish_owned_programs(db, target),
    )


@app.get("/api/users/{user_id}/exercises", response_model=SharedExercises)
def user_exercises(
    user_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found.")
    return SharedExercises(
        user=SharedUser(id=target.id, name=target.name),
        exercises=_publish_owned_exercises(db, target),
    )


@app.put("/api/programs/{program_id}")
def upsert_program(
    program_id: str,
    body: ProgramBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    program = dict(body.program)
    program["id"] = program_id
    sp = db.get(SharedProgram, program_id)
    version = _now_ms()
    if sp is None:
        sp = SharedProgram(
            id=program_id,
            owner_id=user.id,
            owner_name=user.name,
            collaborative=bool(program.get("collaborative")),
            version=version,
            updated_by=user.id,
        )
        sp.data = json.dumps(_enrich(program, sp))
        db.add(sp)
        _ensure_member(db, program_id, user.id)
    else:
        is_owner = sp.owner_id == user.id
        is_member = (
            db.query(ProgramMember)
            .filter(
                ProgramMember.program_id == program_id,
                ProgramMember.user_id == user.id,
            )
            .first()
            is not None
        )
        if is_owner:
            sp.collaborative = bool(program.get("collaborative"))
        elif sp.collaborative and is_member:
            pass  # collaborator may edit content; ownership/flag unchanged
        else:
            raise HTTPException(status_code=403, detail="You can't edit this program.")
        sp.version = version
        sp.updated_by = user.id
        sp.data = json.dumps(_enrich(program, sp))
    db.commit()
    db.refresh(sp)
    return {"program": json.loads(sp.data)}


@app.get("/api/programs/{program_id}")
def get_program(
    program_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    sp = db.get(SharedProgram, program_id)
    if sp is None:
        raise HTTPException(status_code=404, detail="Program not found.")
    return {"program": json.loads(sp.data)}


@app.post("/api/programs/batch")
def programs_batch(
    body: BatchBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    out: list[dict] = []
    for pid in body.ids[:200]:
        sp = db.get(SharedProgram, pid)
        if sp is not None:
            out.append(json.loads(sp.data))
    return {"programs": out}


@app.post("/api/programs/{program_id}/add")
def add_program_member(
    program_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    sp = db.get(SharedProgram, program_id)
    if sp is None:
        raise HTTPException(status_code=404, detail="Program not found.")
    _ensure_member(db, program_id, user.id)
    db.commit()
    return {"program": json.loads(sp.data)}


@app.delete("/api/programs/{program_id}/member")
def remove_program_member(
    program_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    db.query(ProgramMember).filter(
        ProgramMember.program_id == program_id,
        ProgramMember.user_id == user.id,
    ).delete()
    db.commit()
    return {"ok": True}


@app.put("/api/exercises/{exercise_id}")
def upsert_exercise(
    exercise_id: str,
    body: ExerciseBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    exercise = dict(body.exercise)
    exercise["id"] = exercise_id
    se = db.get(SharedExercise, exercise_id)
    version = _now_ms()
    if se is None:
        se = SharedExercise(
            id=exercise_id,
            owner_id=user.id,
            owner_name=user.name,
            collaborative=bool(exercise.get("collaborative")),
            data="{}",
            version=version,
            updated_by=user.id,
        )
        se.data = json.dumps(_enrich_exercise(exercise, se))
        db.add(se)
        _ensure_exercise_member(db, exercise_id, user.id)
    else:
        is_owner = se.owner_id == user.id
        is_member = (
            db.query(ExerciseMember)
            .filter(
                ExerciseMember.exercise_id == exercise_id,
                ExerciseMember.user_id == user.id,
            )
            .first()
            is not None
        )
        if is_owner:
            # Only the owner controls the edit policy (collaborative flag).
            se.collaborative = bool(exercise.get("collaborative"))
        elif se.collaborative and is_member:
            pass  # a collaborator may edit content; ownership/policy unchanged
        else:
            raise HTTPException(status_code=403, detail="You can't edit this exercise.")
        se.version = version
        se.updated_by = user.id
        se.data = json.dumps(_enrich_exercise(exercise, se))
    db.commit()
    db.refresh(se)
    return {"exercise": json.loads(se.data)}


@app.get("/api/exercises/{exercise_id}")
def get_exercise(
    exercise_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    se = db.get(SharedExercise, exercise_id)
    if se is None:
        raise HTTPException(status_code=404, detail="Exercise not found.")
    return {"exercise": json.loads(se.data)}


@app.post("/api/exercises/batch")
def exercises_batch(
    body: BatchBody,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    out: list[dict] = []
    for eid in body.ids[:200]:
        se = db.get(SharedExercise, eid)
        if se is not None:
            out.append(json.loads(se.data))
    return {"exercises": out}


@app.post("/api/exercises/{exercise_id}/add")
def add_exercise_member(
    exercise_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    se = db.get(SharedExercise, exercise_id)
    if se is None:
        raise HTTPException(status_code=404, detail="Exercise not found.")
    _ensure_exercise_member(db, exercise_id, user.id)
    db.commit()
    return {"exercise": json.loads(se.data)}


@app.delete("/api/exercises/{exercise_id}/member")
def remove_exercise_member(
    exercise_id: str,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    db.query(ExerciseMember).filter(
        ExerciseMember.exercise_id == exercise_id,
        ExerciseMember.user_id == user.id,
    ).delete()
    db.commit()
    return {"ok": True}


# ---- Static frontend (optional) ----
# When a built frontend is present (app/static), serve it from the same origin
# as the API. This avoids cross-origin/CORS issues behind an authenticated
# tunnel. API routes above take precedence over the SPA catch-all below.
_STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
_INDEX = os.path.join(_STATIC_DIR, "index.html")

if os.path.isfile(_INDEX):
    _assets = os.path.join(_STATIC_DIR, "assets")
    if os.path.isdir(_assets):
        app.mount("/assets", StaticFiles(directory=_assets), name="assets")

    @app.get("/{full_path:path}")
    def spa(full_path: str):
        candidate = os.path.join(_STATIC_DIR, full_path)
        if full_path and os.path.isfile(candidate):
            return FileResponse(candidate)
        return FileResponse(_INDEX)
