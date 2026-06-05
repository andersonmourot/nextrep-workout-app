---
name: testing-smellis-app
description: End-to-end feature & persistence testing for the SMELLIS workout app (React + FastAPI). Use when verifying per-user data persistence, shared content in search, nutrition/max-tracker, or admin gating.
---

# Testing the SMELLIS workout app

React (Vite/TS, Zustand) frontend + FastAPI/SQLAlchemy backend. State is a single per-user JSON blob synced to the backend via `PUT /api/data` and restored on login.

## Live environment
- Frontend: https://dist-bonpfmfm.devinapps.com (Vercel-style static deploy on devinapps.com)
- Backend: https://smellis-api.fly.dev (Fly.io app `smellis-api`)
- Repo: github.com/andersonmourot/smellis-workout-app (PR #1 is the long-lived feature PR)

## Test accounts (created for testing; password `Testpass123!`)
- Admin tester: `aaron.smellis...@example.com` — admin ONLY while its email is in ADMIN_EMAILS
- Sharer / non-admin: `bella.smellis...@example.com` — has a shareable custom exercise ("Bulgarian Split Squat"), no shared program

Create fresh accounts via the signup page if these are gone. To test sharing you need two accounts: one that toggles an exercise/program "Shareable", and one that searches for it.

## Admin gating
- Admin access is controlled by the Fly secret `ADMIN_EMAILS` (comma-separated emails). Only those emails get `is_admin: true` on the PublicUser and can see Settings -> Users and call `GET /api/admin/users` (403 otherwise).
- To temporarily make a test account admin: `~/.fly/bin/flyctl secrets set ADMIN_EMAILS="owner@email,tester@email" -a smellis-api` (triggers a rolling restart).
- IMPORTANT: revert ADMIN_EMAILS back to just the real owner email after testing.
- The real owner admin is `andersonmourot@aol.com`.

## Persistence model (what to verify)
The store snapshot includes per-user: name, theme color/mode, weight unit, custom programs/exercises, exercise photos/edits, hidden/deleted defaults, saved timers, end-of-timer (Alert) sound, interval settings, `favoriteUserIds` (max 3), `nutritionLog` (keyed by ISO date), `nutritionGoals`, `maxTrackers`. On load the app merges `{ ...defaults, ...saved }` so older accounts backfill new fields with no crash.

**Strongest persistence test = full logout + re-login** (not just reload) — this clears local in-memory state and rehydrates from the backend.

## Key routes
- `/people` (bottom nav "Search"), `/progress` (bottom nav "Profile"), `/nutrition`, `/max`, `/max/:id`, `/settings`, `/admin/users` (admin only; non-admins are redirected to Home).

## Golden-path test checklist
1. Search another user -> their card expands into Programs / Exercises sections; shared exercise must appear (was a bug). Empty sections render blank (no "0 programs").
2. Add a shared exercise -> button flips to "Added", copies into your library.
3. Favorite (star) a followed user -> pins to top of Following; max 3.
4. Profile body-weight date shows `Mon D, YYYY` (NO weekday).
5. Nutrition: log calories/macros/water; edit goals -> ring target updates.
6. Max Tracker: create entry (weight x reps), add a 2nd dated record -> detail page shows history + trend line chart.
7. Log out + log back in -> nutrition, max trackers, favorites all restored.
8. Admin account: Settings shows Users card -> page lists all users (name, email, join date, NO passwords).
9. Non-admin: no Users card; `/admin/users` redirects to Home.

## Gotchas
- An environment restart can kill an active screen recording (recording_stop reports "No active recording") and log the browser out. Because data persists server-side, you can simply re-record the full run and it doubles as the persistence proof. Consider keeping recordings shorter / annotate as you go.
- `git_comment_on_pr` sometimes returns 'Internal Server Error'. Workaround that worked: post via `gh pr comment 1 --body-file <file>` (gh CLI is authenticated for this repo; embedded devin attachment image URLs render fine).
- Login form: email field then password field then submit; allow ~2.5s after submit for the data sync/redirect.
- flyctl may not be on PATH after a restart; use `~/.fly/bin/flyctl`.

## Devin Secrets Needed
- None required beyond what's pre-configured. Fly auth (`flyctl`) and `gh` CLI are already authenticated in this environment. App test-account passwords are not secrets (`Testpass123!`).
