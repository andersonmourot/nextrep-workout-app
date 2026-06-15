# Test Plan — Permanent backend deploy (cross-device accounts)

App (public): https://dist-bonpfmfm.devinapps.com
Backend (permanent): https://smellis-api.fly.dev

What changed: backend moved from a session-tied tunnel (basic-auth popup) to a permanent, always-on Fly.io host; frontend rebuilt to point at it. A broken deploy would show network errors or data failing to load on a second device.

## Test 1 — Cross-device account sync (PRIMARY)
Steps:
1. On Device 1 (normal window), go to /signup. Create account: name "Cross Device", unique email `xdev+<ts>@example.com`, password `testpass123`. Click Create account.
   - PASS: redirected into the app (Dashboard/Programs), no error banner, no auth popup.
2. Go to Programs, pick a distinctive program (e.g. "Powerlifting Peak"), open it, click "Set as Active".
   - PASS: program shows as active (Dashboard "today" card / active badge reflects it).
3. Open a fresh incognito window (Device 2 — no shared storage). Go to /login. Log in with the SAME email + password.
   - PASS: login succeeds.
4. Observe the Dashboard on Device 2.
   - PASS (decisive): the active program from step 2 appears on Device 2. Since incognito shares no localStorage, this data could ONLY have come from the server. If it were broken, Device 2 would show no active program / empty state.

## Test 2 — Auth security (wrong password rejected)
Steps:
1. On /login, enter the correct email but a WRONG password. Submit.
   - PASS: stays on /login, banner reads "Incorrect email or password." (backend returns 401).

## Evidence
- Record the full run; annotate signup, set-active, device-2 login, and the decisive data-load assertion.
- Capture screenshots of Device 1 active program and Device 2 Dashboard showing the same program.
