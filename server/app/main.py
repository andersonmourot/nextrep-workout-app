import json
import os
import secrets

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from .db import Base, engine, get_db
from .models import User
from .security import create_token, decode_token, hash_password, verify_password

Base.metadata.create_all(bind=engine)

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


class PublicUser(BaseModel):
    id: str
    name: str
    email: str


class AuthResponse(BaseModel):
    token: str
    user: PublicUser


class DataBody(BaseModel):
    data: dict


# ---- Helpers ----
def _public(user: User) -> PublicUser:
    return PublicUser(id=user.id, name=user.name, email=user.email)


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
    return AuthResponse(token=create_token(user.id), user=_public(user))


@app.get("/me", response_model=PublicUser)
def me(user: User = Depends(current_user)):
    return _public(user)


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
