---
name: testing-nextrep-app
description: End-to-end UI testing for the NextRep workout app (social/search, custom-exercise sharing, active-workout inputs, start-day activation). Use when verifying NextRep frontend/backend changes against the live build.
---

# Testing the NextRep workout app

## Environments
- **Live frontend (prod):** https://dist-bonpfmfm.devinapps.com (public)
- **Backend API:** https://smellis-api.fly.dev (Fly.io)
- **Repo:** andersonmourot/nextrep-workout-app (folder on disk may still be `stndrd-workout-app`)
- Deploys are gated behind an approval card; the live URL keeps serving the old build until approved.

## User preferences
- **Do NOT record screen videos.** This user prefers screenshots + text evidence. Only record if explicitly asked.
- Report results as ONE GitHub comment on the open PR, using `<details>/<summary>` collapsible sections and a results table. Include the Devin session link.

## QA account conventions
- Create throwaway accounts via the normal signup screen.
- Accounts with an **`@example.com`** email are treated as test/seed accounts and are **hidden from user search** (this is intended behavior — use it to verify search-hiding).
- A "real" searchable account needs a non-`@example.com` domain (e.g. `@nextrepqa.app`).
- Use a shared random token in display names (e.g. `Zphx7`) so you can search for your own test cohort.

## Key flows & how to verify
- **Search hiding:** Search the shared token as a follower; only non-`@example.com` accounts should appear.
- **Custom-exercise transfer:** As a creator, make a custom exercise + a collaborative program using it. As a follower, follow + add the program, then open it — the exercise must show its real name, NOT a raw `custom-ex-…` id.
- **Rename sync:** Rename the creator in Settings; wait ~2s (debounced `/api/data` sync, ~600ms throttle) before searching again as the follower. New name should appear; old name gone.
- **Active-workout inputs:** Weight/Reps boxes should be erasable to blank (faint `0` placeholder) and have NO up/down stepper arrows. Inputs are `type="text"` with `placeholder="0"`.

## Gotcha: start-day "Switch active program?" popup (#6)
The confirm popup when starting a day on a *different* program only appears when the **current** active program has saved progress. The trigger requires EITHER:
- a **finished/logged** workout on the active program (logs are created by pressing **Finish Workout**, NOT by marking a single set Done), OR
- a live in-progress `activeWorkout` on that program.

Leaving a workout via the **X (Exit)** button calls `endWorkout()`, which clears the in-progress state and discards unsaved sets. So to reliably trigger the popup: start + **Finish** a workout on program A, then press Start on program B. Otherwise the switch happens silently (which is correct behavior, not a bug).

## Not testable from desktop
- **iOS standalone scroll/safe-area bugs** — cannot reproduce iOS standalone (Add to Home Screen) viewport behavior in a desktop browser. Needs on-device confirmation from the user; ask for a screen recording of the launch and (if debugging viewport height) a diagnostic build that prints `screen.height` vs `window.innerHeight`. Note: iOS first-paint under-reports `innerHeight` by the top safe-area inset; `screen.height` is the reliable value.
- **Admin pages** — require the prod admin password (not available). Validate admin-only changes via a local backend run (e.g. FastAPI TestClient) instead.

## Devin Secrets Needed
- None currently stored. Prod admin password is NOT available — admin features must be validated locally. If repeated admin testing is needed, ask the user to provide an admin credential to save for future sessions.
