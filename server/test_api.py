#!/usr/bin/env python3
"""End-to-end backend test suite against a local uvicorn instance on :8002.

Covers auth validation, legacy-password compatibility, token auth, data
round-trip fidelity, search/seed-account hiding, follow, shared
exercise/program flows, admin gating, and the password-reset lifecycle.
"""
import json
import os
import sqlite3
import sys
import urllib.request
import urllib.error
from datetime import datetime, timedelta, timezone

SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SERVER_DIR)
from app.security import hash_password, generate_reset_token, hash_reset_token  # noqa: E402

# Point at a locally running instance, e.g.:
#   SMELLIS_DB_PATH=/tmp/test.db SECRET_KEY=x MIN_IOS_VERSION=1.1 #     ADMIN_EMAILS=admin@test.dev uvicorn app.main:app --port 8002
BASE = os.environ.get("TEST_API_BASE", "http://localhost:8002")
DB = os.environ.get("TEST_DB_PATH", "/tmp/nextrep-test.db")
PASS = "PASS"
results = []


def req(method, path, body=None, token=None):
    r = urllib.request.Request(BASE + path, method=method)
    r.add_header("Content-Type", "application/json")
    if token:
        r.add_header("X-Auth-Token", token)
    data = json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(r, data=data, timeout=10) as resp:
            return resp.status, json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read() or b"{}")
        except Exception:
            return e.code, {}


def check(name, cond, detail=""):
    results.append((name, bool(cond), detail))
    print(("PASS " if cond else "FAIL ") + name + (f"  [{detail}]" if detail and not cond else ""))


# ---------- health / meta / catalog ----------
s, b = req("GET", "/health")
check("health", s == 200 and b.get("ok") is True)

s, b = req("GET", "/api/meta")
check("meta returns min version", s == 200 and b.get("min_supported_ios_version") == "1.1", str(b))

s, b = req("GET", "/api/catalog")
check("catalog has programs+exercises",
      s == 200 and len(b.get("programs", [])) > 0 and len(b.get("exercises", [])) > 0,
      f"programs={len(b.get('programs', []))} exercises={len(b.get('exercises', []))}")

# ---------- signup validation ----------
s, _ = req("POST", "/auth/signup", {"name": "Short", "email": "short@test.dev", "password": "abc123"})
check("signup rejects password <10", s == 422, f"status={s}")

s, _ = req("POST", "/auth/signup", {"name": "Bad", "email": "not-an-email", "password": "longenough1"})
check("signup rejects bad email", s == 422, f"status={s}")

s, b = req("POST", "/auth/signup", {"name": "Alice QA", "email": "alice@qareal.dev", "password": "password123"})
check("signup succeeds", s == 200 and bool(b.get("token")), f"status={s}")
alice_token = b.get("token", "")
alice_id = (b.get("user") or {}).get("id", "")

s, b = req("POST", "/auth/signup", {"name": "Dup", "email": "ALICE@qareal.dev", "password": "password123"})
check("duplicate email -> 409 (case-insensitive)", s == 409, f"status={s}")

# ---------- legacy short-password account still logs in ----------
con = sqlite3.connect(DB)
con.execute(
    "INSERT INTO users (id, name, email, password_hash, data, created_at) VALUES (?,?,?,?,?,?)",
    ("legacyuser1", "Legacy User", "legacy@qareal.dev", hash_password("abc123"), "{}", datetime.now(timezone.utc).isoformat()),
)
con.commit()
con.close()
s, b = req("POST", "/auth/login", {"email": "legacy@qareal.dev", "password": "abc123"})
check("legacy short password still logs in", s == 200 and bool(b.get("token")), f"status={s}")

# ---------- login failures + throttle ----------
s, _ = req("POST", "/auth/login", {"email": "alice@qareal.dev", "password": "wrongpassword"})
check("wrong password -> 401", s == 401, f"status={s}")

s, b = req("POST", "/auth/login", {"email": "alice@qareal.dev", "password": "password123"})
check("correct login", s == 200, f"status={s}")

throttle_status = None
for i in range(11):
    throttle_status, _ = req("POST", "/auth/login", {"email": "nobody@qareal.dev", "password": "x"})
check("login throttles after 10 failures -> 429", throttle_status == 429, f"status={throttle_status}")

# ---------- token auth ----------
s, b = req("GET", "/me", token=alice_token)
check("/me returns user", s == 200 and b.get("email") == "alice@qareal.dev", f"status={s}")
s, _ = req("GET", "/me")
check("/me without token -> 401/403", s in (401, 403), f"status={s}")
s, _ = req("GET", "/me", token="garbage-token")
check("/me bad token -> 401/403", s in (401, 403), f"status={s}")

# ---------- data round-trip ----------
blob = {
    "programSetMemory": {"prog-1": {"ex-bench": [{"weight": 135.5, "reps": 8, "completed": True}]}},
    "programWeightMemory": {"prog-1": {"ex-bench": [135.5]}},
    "someFutureUnknownField": {"nested": [1, 2, {"deep": True}]},
    "logs": [{"id": "l1", "exercises": [{"exerciseId": "custom-swap-day-1-0", "name": "Ring Rows"}]}],
}
s, _ = req("PUT", "/api/data", {"data": blob}, token=alice_token)
check("PUT /api/data", s == 200, f"status={s}")
s, b = req("GET", "/api/data", token=alice_token)
if isinstance(b, dict):
    b.pop("serverUpdatedAt", None)
check("GET /api/data round-trips all client keys", s == 200 and b == blob,
      f"status={s} keys={sorted(b.keys()) if isinstance(b, dict) else b}")
s, _ = req("PUT", "/api/data", {"data": blob})
check("PUT /api/data without token -> 401/403", s in (401, 403), f"status={s}")

# ---------- search + seed-account hiding ----------
s, b = req("POST", "/auth/signup", {"name": "SeedTwin Qz9", "email": "seed@example.com", "password": "password123"})
seed_ok = s == 200
s, b = req("POST", "/auth/signup", {"name": "RealTwin Qz9", "email": "real@qareal.dev", "password": "password123"})
check("second user signup", s == 200 and bool(b.get("token")), f"status={s}")
bob_token = b.get("token", "")
bob_id = (b.get("user") or {}).get("id", "")

s2, b2 = req("POST", "/auth/signup", {"name": "HiddenTwin Qz9", "email": "hidden@nextrepqa.app", "password": "password123"})
s, b = req("GET", "/api/users/search?q=Qz9", token=alice_token)
names = [u["name"] for u in (b if isinstance(b, list) else [])]
check("search hides seed domains (@example.com + @nextrepqa.app)",
      s == 200 and "RealTwin Qz9" in names and "SeedTwin Qz9" not in names and "HiddenTwin Qz9" not in names,
      f"names={names}")

s, _ = req("GET", "/api/users/search?q=Qz9")
check("search requires auth", s in (401, 403), f"status={s}")

# ---------- follow ----------
s, _ = req("POST", f"/api/users/{bob_id}/follow", token=alice_token)
check("follow", s == 200, f"status={s}")
s, b = req("GET", "/api/following", token=alice_token)
check("following list", s == 200 and any(u.get("id") == bob_id for u in b), f"status={s}")
s, _ = req("DELETE", f"/api/users/{bob_id}/follow", token=alice_token)
check("unfollow", s == 200, f"status={s}")
s, b = req("GET", "/api/following", token=alice_token)
check("following empty after unfollow", s == 200 and not any(u.get("id") == bob_id for u in b), f"status={s}")

# ---------- shared exercise flow ----------
shared_blob = {
    "customExercises": [{
        "id": "ex-shared-1", "name": "Bulgarian Split Squat", "primaryMuscle": "Quads",
        "secondaryMuscles": [], "equipment": "DB", "difficulty": "Int",
        "instructions": [], "tips": [], "shared": True, "version": 1,
    }]
}
s, _ = req("PUT", "/api/data", {"data": shared_blob}, token=bob_token)
check("bob publishes shared exercise via blob", s == 200, f"status={s}")

s, b = req("GET", f"/api/users/{bob_id}/exercises", token=alice_token)
check("alice sees bob's shared exercise", s == 200 and any(e.get("id") == "ex-shared-1" for e in b.get("exercises", [])),
      f"status={s} body={b}")

s, b = req("POST", "/api/exercises/ex-shared-1/add", token=alice_token)
check("alice adds shared exercise -> enriched copy", s == 200 and b.get("exercise", {}).get("name") == "Bulgarian Split Squat",
      f"status={s}")

s, _ = req("POST", "/api/exercises/does-not-exist/add", token=alice_token)
check("add unknown exercise -> 404", s == 404, f"status={s}")

# Owner edits propagate: bob updates the shared exercise name via PUT endpoint
s, b = req("GET", "/api/exercises/ex-shared-1", token=bob_token)
ex = b.get("exercise") or {}
ex["name"] = "Bulgarian Split Squat v2"
s, _ = req("PUT", "/api/exercises/ex-shared-1", {"exercise": ex}, token=bob_token)
check("owner updates shared exercise", s == 200, f"status={s}")
s, b = req("GET", "/api/exercises/ex-shared-1", token=alice_token)
check("edit propagates to adder", s == 200 and (b.get("exercise") or {}).get("name") == "Bulgarian Split Squat v2",
      f"status={s}")

# non-owner/non-collaborative write -> 403
ex["name"] = "Hijack"
s, _ = req("PUT", "/api/exercises/ex-shared-1", {"exercise": ex}, token=alice_token)
check("non-owner edit blocked -> 403", s == 403, f"status={s}")

# ---------- shared program flow ----------
prog = {
    "id": "prog-shared-1", "name": "Bob's Plan", "category": "Strength", "level": "Beg",
    "coach": "Bob", "durationWeeks": 4, "daysPerWeek": 1, "accent": "#fff",
    "summary": "", "description": "", "shared": True, "version": 1,
    "days": [{"id": "d1", "name": "Day 1", "focus": "", "exercises": [
        {"exerciseId": "ex-shared-1", "sets": 3, "reps": "10", "restSec": 90}
    ]}],
}
req("PUT", "/api/data", {"data": {**shared_blob, "customPrograms": [prog]}}, token=bob_token)
s, b = req("GET", f"/api/users/{bob_id}/programs", token=alice_token)
check("alice sees bob's shared program", s == 200 and any(p.get("id") == "prog-shared-1" for p in b.get("programs", [])),
      f"status={s} body={b}")

s, b = req("POST", "/api/programs/prog-shared-1/add", token=alice_token)
added = b.get("program") or {}
# Name resolution must prefer the canonical store over the owner's stale blob
# (bob renamed to v2 via PUT /api/exercises but his blob still says v1).
check("alice adds program -> canonical name (not stale blob name)",
      s == 200 and (added.get("days") or [{}])[0].get("exercises", [{}])[0].get("name") == "Bulgarian Split Squat v2",
      f"status={s} day={ (added.get('days') or [{}])[0].get('exercises') }")

s, b = req("POST", "/api/programs/batch", {"ids": ["prog-shared-1", "missing-id"]}, token=alice_token)
check("programs batch fetch", s == 200 and any(p.get("id") == "prog-shared-1" for p in b.get("programs", [])),
      f"status={s}")

# ---------- admin gating ----------
s, _ = req("GET", "/api/admin/users", token=alice_token)
check("admin users blocked for non-admin -> 403", s == 403, f"status={s}")

s, b = req("POST", "/auth/signup", {"name": "Admin QA", "email": "admin@test.dev", "password": "password123"})
admin_token = b.get("token", "")
s, b = req("GET", "/api/admin/users", token=admin_token)
check("admin users allowed, hides seed accounts", s == 200 and isinstance(b, list) and 1 <= len(b) <= 5 and all(not u["email"].endswith(("@example.com","@nextrepqa.app")) for u in b),
      f"status={s} n={len(b) if isinstance(b, list) else '?'}")

# ---------- password change ----------
s, _ = req("POST", "/auth/password", {"current_password": "wrongpassword", "new_password": "newpassword1"}, token=alice_token)
check("change pw wrong current -> 401", s == 401, f"status={s}")
s, _ = req("POST", "/auth/password", {"current_password": "password123", "new_password": "short"}, token=alice_token)
check("change pw new <10 -> 422", s == 422, f"status={s}")
s, _ = req("POST", "/auth/password", {"current_password": "password123", "new_password": "password123"}, token=alice_token)
check("change pw same -> 400", s == 400, f"status={s}")
s, _ = req("POST", "/auth/password", {"current_password": "password123", "new_password": "newpassword1"}, token=alice_token)
check("change pw success", s == 200, f"status={s}")
s, _ = req("POST", "/auth/login", {"email": "alice@qareal.dev", "password": "newpassword1"})
check("login with new password", s == 200, f"status={s}")

# ---------- reset-password lifecycle ----------
s, b = req("POST", "/auth/forgot-password", {"email": "alice@qareal.dev"})
check("forgot-password always ok", s == 200 and b.get("ok") is True, f"status={s}")
s, b = req("POST", "/auth/forgot-password", {"email": "ghost@qareal.dev"})
check("forgot-password unknown email still ok (no enumeration)", s == 200 and b.get("ok") is True, f"status={s}")

# Seed a valid reset token directly (the emailed raw token can't be recovered)
raw = generate_reset_token()
con = sqlite3.connect(DB)
con.execute("UPDATE users SET reset_token_hash=?, reset_token_expires=? WHERE email=?",
            (hash_reset_token(raw), (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(), "alice@qareal.dev"))
con.commit(); con.close()

s, _ = req("POST", "/auth/reset-password", {"token": raw, "new_password": "resetpassword1"})
check("reset-password with valid token", s == 200, f"status={s}")
s, _ = req("POST", "/auth/login", {"email": "alice@qareal.dev", "password": "resetpassword1"})
check("login after reset", s == 200, f"status={s}")
s, _ = req("POST", "/auth/reset-password", {"token": raw, "new_password": "resetpassword2"})
check("reset token single-use", s == 400, f"status={s}")
s, _ = req("POST", "/auth/reset-password", {"token": "bogus-token", "new_password": "resetpassword2"})
check("reset bogus token -> 400", s == 400, f"status={s}")
s, _ = req("POST", "/auth/reset-password", {"token": raw, "new_password": "tiny"})
check("reset new password <10 -> 422", s == 422, f"status={s}")

# Expired token path
raw2 = generate_reset_token()
con = sqlite3.connect(DB)
con.execute("UPDATE users SET reset_token_hash=?, reset_token_expires=? WHERE email=?",
            (hash_reset_token(raw2), (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat(), "alice@qareal.dev"))
con.commit(); con.close()
s, _ = req("POST", "/auth/reset-password", {"token": raw2, "new_password": "resetpassword3"})
check("expired reset token -> 400", s == 400, f"status={s}")

# ---------- summary ----------
fails = [r for r in results if not r[1]]
print(f"\n{'='*50}\n{len(results)-len(fails)}/{len(results)} passed")
for name, _, detail in fails:
    print(f"  FAIL {name} {detail}")
sys.exit(1 if fails else 0)
