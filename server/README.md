# SMELLIS Backend

FastAPI service providing secure, cross-device accounts for the SMELLIS workout app:
secure signup/login (PBKDF2-hashed passwords + JWT) and per-user data sync.

## Endpoints

| Method | Path           | Auth | Description                              |
| ------ | -------------- | ---- | ---------------------------------------- |
| GET    | `/health`      | no   | Liveness check                           |
| POST   | `/auth/signup` | no   | Create account → `{ token, user }`       |
| POST   | `/auth/login`  | no   | Log in → `{ token, user }`               |
| GET    | `/me`          | yes  | Current account                          |
| GET    | `/api/data`    | yes  | Fetch the user's app data (JSON blob)    |
| PUT    | `/api/data`    | yes  | Replace the user's app data              |

Auth token is read from the `X-Auth-Token` header (falls back to
`Authorization: Bearer <token>`). `X-Auth-Token` is used so the app token does
not collide with an upstream proxy/tunnel that uses HTTP basic auth on
`Authorization`.

If a built frontend is present at `app/static/`, it is served from the same
origin as the API (with SPA fallback), avoiding cross-origin/CORS issues.

## Run locally

```bash
cd server
uv venv .venv && source .venv/bin/activate
uv pip install -r requirements.txt
SECRET_KEY="$(openssl rand -hex 24)" uvicorn app.main:app --reload --port 8000
```

## Configuration

| Env var           | Default                       | Notes                                        |
| ----------------- | ----------------------------- | -------------------------------------------- |
| `SECRET_KEY`      | dev placeholder               | **Set a strong value (≥32 bytes) in prod.**  |
| `SMELLIS_DB_PATH` | `/data/smellis.db` or `./smellis.db` | SQLite file path                      |
| `DATABASE_URL`    | (unset)                       | Overrides the SQLite URL entirely            |

## Deploy

The SQLite database should live on a persistent volume mounted at `/data`
(the default DB path uses `/data` when present). Set a strong `SECRET_KEY`.
Start command: `uvicorn app.main:app --host 0.0.0.0 --port 8080`.
