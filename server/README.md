# SMELLIS Backend

FastAPI service providing secure, cross-device accounts for the SMELLIS workout app:
secure signup/login (PBKDF2-hashed passwords + JWT) and per-user data sync.

## Endpoints

| Method | Path                              | Auth  | Description                                        |
| ------ | --------------------------------- | ----- | -------------------------------------------------- |
| GET    | `/health`                         | no    | Liveness check                                     |
| GET    | `/api/catalog`                    | no    | Built-in programs + exercises catalog              |
| PUT    | `/api/admin/catalog`              | admin | Replace the catalog (persisted to the data volume) |
| POST   | `/auth/signup`                    | no    | Create account → `{ token, user }`                 |
| POST   | `/auth/login`                     | no    | Log in → `{ token, user }`                         |
| POST   | `/auth/password`                  | yes   | Change password                                    |
| POST   | `/auth/forgot-password`           | no    | Email a reset link (always returns ok)             |
| POST   | `/auth/reset-password`            | no    | Complete a password reset                          |
| GET    | `/me`                             | yes   | Current account                                    |
| DELETE | `/api/account`                    | yes   | Permanently delete current account                 |
| GET    | `/api/admin/users`                | admin | List users (seed/test accounts hidden)             |
| POST   | `/api/admin/users/{id}/reset-password` | admin | Set a user's password directly                |
| GET    | `/api/data`                       | yes   | Fetch the user's app data (JSON blob)              |
| PUT    | `/api/data`                       | yes   | Replace the user's app data (max 5 MB)             |
| GET    | `/api/users/search?q=`            | yes   | Search users by name (seed accounts hidden)        |
| POST   | `/api/users/{id}/follow`          | yes   | Follow a user                                      |
| DELETE | `/api/users/{id}/follow`          | yes   | Unfollow a user                                    |
| GET    | `/api/following`                  | yes   | List followed users                                |
| GET    | `/api/users/{id}/programs`        | yes   | A user's shared programs (publish-on-read)         |
| GET    | `/api/users/{id}/exercises`       | yes   | A user's shared exercises (publish-on-read)        |
| PUT    | `/api/programs/{id}`              | yes   | Create/update a shared program (owner or collaborator) |
| GET    | `/api/programs/{id}`              | yes   | Fetch a shared program                             |
| POST   | `/api/programs/batch`             | yes   | Fetch many shared programs by id                   |
| POST   | `/api/programs/{id}/add`          | yes   | Join a program (member → syncs updates)            |
| DELETE | `/api/programs/{id}/member`       | yes   | Leave a program                                    |
| PUT    | `/api/exercises/{id}`             | yes   | Create/update a shared exercise                    |
| GET    | `/api/exercises/{id}`             | yes   | Fetch a shared exercise                            |
| POST   | `/api/exercises/batch`            | yes   | Fetch many shared exercises by id                  |
| POST   | `/api/exercises/{id}/add`         | yes   | Add a shared exercise to your library              |
| DELETE | `/api/exercises/{id}/member`      | yes   | Remove a shared exercise membership                |

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
