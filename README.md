# SMELLIS — Workout App

A polished, mobile-first workout app for serious training. Browse training programs, run guided workouts with set/rep/tempo tracking and a rest timer, study an exercise library, and track your progress over time.

> Built as an independent, open-source project.

## Features

- **Programs library** — 6 seeded programs across Bodybuilding, Strength, HIIT, Powerlifting, Functional, and Bodyweight, each with a multi-day split, tempo prescriptions, and rest targets.
- **Custom programs** — build your own program with the same options as the built-ins (name, category, level, goal, duration, accent color, and a day-by-day exercise builder with sets/reps/tempo/rest). Custom programs are editable, persist locally, and work everywhere the built-ins do.
- **Manage & delete** — a Manage toggle on the Programs page lets you delete any program (including the seeded built-ins) with a confirm step, and restore the default programs at any time.
- **Guided workout player** — work through each exercise set-by-set, log weight & reps with quick steppers, mark sets complete, and get an automatic rest-timer countdown (with skip / +15s). Finish to a workout summary.
- **Exercise library** — 30+ exercises with primary/secondary muscles, equipment, difficulty, step-by-step instructions, coaching cues, and recommended tempo. Searchable and filterable by muscle group.
- **Progress tracking** — body-weight log with a trend chart, workout history, streaks, and total training volume.
- **Account sync** — logged-in users sync data through the FastAPI backend, with per-user browser storage as the fast local cache.

## Tech stack

- [React 19](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vite.dev/) for dev/build
- [Tailwind CSS](https://tailwindcss.com/) for styling
- [React Router](https://reactrouter.com/) for routing
- [Zustand](https://zustand-demo.pmnd.rs/) (with `persist`) for state
- [lucide-react](https://lucide.dev/) icons
- [FastAPI](https://fastapi.tiangolo.com/) backend in `server/` for auth, sync, catalog, and social sharing

## Getting started

```bash
npm install
npm run dev      # start the dev server (http://localhost:5173)
```

Other scripts:

```bash
npm run build    # type-check and build for production -> dist/
npm run preview  # preview the production build
npm run lint     # run ESLint
```

## Project structure

```
src/
  components/    # Layout, BottomNav, Logo, ProgressRing, ...
  data/          # exercises.ts, programs.ts (seed content)
  pages/         # Dashboard, Programs, ProgramDetail, ProgramEditor, Workout, Exercises, ExerciseDetail, Progress, Settings
  lib/utils.ts   # formatting + progress helpers
  store.ts       # zustand store (persisted)
  types.ts       # shared types
server/          # FastAPI backend and SQLite-backed sync/social API
docs/            # Native iOS handoff and SwiftUI screen specs
ios/             # Source-only SwiftUI starter scaffold
```

## Native iOS migration

The native iOS rewrite should be a SwiftUI client that reuses the existing
FastAPI backend, not a WebView wrapper. Start here:

- `docs/ios-swiftui-handoff.md` — API, data model, gotchas, and phase plan
- `docs/ios-swiftui-screens.md` — screen-by-screen SwiftUI spec
- `ios/NextRepStarter/` — source-only Phase 0 SwiftUI scaffold for login,
  Keychain token storage, `/api/catalog`, `/api/data`, and a read-only Programs tab

## Notes

When logged in, app data syncs through the backend's whole-blob `GET /api/data`
and `PUT /api/data` endpoints. Browser storage is still used as a local cache;
clearing site data removes the local cache but not the backend copy.
