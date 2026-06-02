# STNDRD — Workout App

A polished, mobile-first workout app inspired by the [STNDRD](https://www.stndrd.app/) (CBUM) training app. Browse training programs, run guided workouts with set/rep/tempo tracking and a rest timer, study an exercise library, and track your progress over time.

> Built as an independent, open-source homage. Not affiliated with or endorsed by STNDRD / Set The Standard, LLC.

## Features

- **Programs library** — 6 seeded programs across Bodybuilding, Strength, HIIT, Powerlifting, Functional, and Bodyweight, each with a multi-day split, tempo prescriptions, and rest targets.
- **Guided workout player** — work through each exercise set-by-set, log weight & reps with quick steppers, mark sets complete, and get an automatic rest-timer countdown (with skip / +15s). Finish to a workout summary.
- **Exercise library** — 30+ exercises with primary/secondary muscles, equipment, difficulty, step-by-step instructions, coaching cues, and recommended tempo. Searchable and filterable by muscle group.
- **Progress tracking** — body-weight log with a trend chart, workout history, streaks, and total training volume.
- **Local-first** — all data persists in the browser via `localStorage` (no account or backend required), so it deploys as a static site.

## Tech stack

- [React 19](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vite.dev/) for dev/build
- [Tailwind CSS](https://tailwindcss.com/) for styling
- [React Router](https://reactrouter.com/) for routing
- [Zustand](https://zustand-demo.pmnd.rs/) (with `persist`) for state
- [lucide-react](https://lucide.dev/) icons

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
  pages/         # Dashboard, Programs, ProgramDetail, Workout, Exercises, ExerciseDetail, Progress, Settings
  lib/utils.ts   # formatting + progress helpers
  store.ts       # zustand store (persisted)
  types.ts       # shared types
```

## Notes

This is a frontend-only project. Workout logs and body-weight entries live in your browser's local storage; clearing site data (or using the in-app **Settings → Reset All Data**) will remove them.
