---
name: web-dev
description: Start the NextRep web frontend dev server (Vite + React, port 5173). Use when running or verifying frontend changes locally.
---

# Local web dev server (Vite + React)

React 19 + TypeScript + Zustand frontend at the repo root, built with Vite.

```sh
# One-time setup:
npm ci

# Run:
npm run dev          # → http://localhost:5173
```

Verify: `curl -s -o /dev/null -w "%{http_code}" http://localhost:5173` → `200`

## Other scripts

- `npm run build` — `tsc -b && vite build` (typecheck + production build to `dist/`)
- `npm run lint` — ESLint
- `npm run preview` — serve the production build locally

## Notes

- API base URL comes from `VITE_API_URL`:
  - `.env.development` → `http://localhost:8000` (pairs with the local backend,
    see the `backend-dev` skill)
  - `.env.production` → `https://smellis-api.fly.dev`
- Live prod frontend: https://dist-bonpfmfm.devinapps.com
- For full-stack local testing, run this together with the local backend.
- End-to-end QA conventions live in `.agents/skills/testing-nextrep-app`.
