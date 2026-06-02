import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone

import jwt

SECRET_KEY = os.environ.get("SECRET_KEY", "smellis-dev-secret-change-me")
ALGORITHM = "HS256"
TOKEN_TTL_DAYS = 30

_PBKDF2_ITERATIONS = 200_000


def hash_password(password: str) -> str:
    """PBKDF2-HMAC-SHA256 with a random per-user salt (stdlib, no native deps)."""
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS
    )
    return f"pbkdf2_sha256${_PBKDF2_ITERATIONS}${salt}${dk.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algo, iters, salt, digest = stored.split("$")
    except ValueError:
        return False
    if algo != "pbkdf2_sha256":
        return False
    dk = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), salt.encode(), int(iters)
    )
    return hmac.compare_digest(dk.hex(), digest)


def create_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(days=TOKEN_TTL_DAYS),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> str | None:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.PyJWTError:
        return None
    sub = payload.get("sub")
    return sub if isinstance(sub, str) else None
