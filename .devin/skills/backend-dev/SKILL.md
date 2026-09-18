---
name: backend-dev
description: Start the NextRep/SMELLIS FastAPI backend locally on port 8000 (server/ directory, uv-managed venv). Use when running or testing the API locally.
---

# Local backend (FastAPI + SQLite)

The backend lives in `server/`. Verified working setup:

```sh
cd server
# One-time setup (uv is installed via Homebrew; it manages its own Python —
# system python3 is 3.9 and too old):
uv venv .venv
uv pip install --python .venv/bin/python -r requirements.txt

# Run (SECRET_KEY has a dev placeholder but set one anyway):
SECRET_KEY="$(openssl rand -hex 24)" \
  .venv/bin/uvicorn app.main:app --reload --port 8000
```

Verify: `curl http://localhost:8000/health` → `{"ok":true}`

## Notes

- SQLite DB defaults to `server/smellis.db` (override with `SMELLIS_DB_PATH`).
- Auth token header: `X-Auth-Token` (also accepts `Authorization: Bearer`).
- Key endpoints: `POST /auth/signup`, `POST /auth/login`, `GET/PUT /api/data`,
  `GET /api/catalog`. Full list in `server/README.md`.
- `PUT /api/data` replaces the ENTIRE user blob — preserve unknown keys.
- If `app/static/` contains a built frontend it is served same-origin.
- Production backend is `https://smellis-api.fly.dev` (Fly.io, `fly.toml`).
- The frontend uses this server when `VITE_API_URL=http://localhost:8000`
  (already set in `.env.development` — `npm run dev` picks it up).
