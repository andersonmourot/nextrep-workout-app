# Test Plan — Per-user persistence & feature availability (NextRep)

Live app: https://dist-bonpfmfm.devinapps.com · Backend: https://smellis-api.fly.dev
Accounts (created on prod, password `Password123!`): **Persist A** (persista_1780772@example.com), **Persist B** (fresh signup during test).

## Architecture under test (evidence)
- All app state is stored per-user as one opaque JSON blob in the backend (`user.data` Text column; `PUT/GET /api/data` — server/app/main.py:594-608). New feature fields persist with no migration.
- Client: per-user local cache keyed `smellis-data-${id}` (store.ts:103-112); on login/init `loadCurrentUserData()` then `syncFromServer()` overwrites local with server blob (auth.ts:41-55,71-81); every change debounce-pushes to backend (store.ts:563-571); `snapshot()` includes themeColor, customPrograms, activeWorkout, nutritionLog (incl. `photos`), bodyWeight, maxTrackers, favoriteProgramIds, completedPrograms (store.ts:513-543).
- New exercises live in code `src/data/exercises.ts:63,106,232` → every account gets them on load.

## Why these tests distinguish working vs broken
- Flow 1 wipes **all** localStorage before re-login. If data were only device-local (not server-synced), everything would reset to defaults → visibly fails. If server-synced, every value returns.
- Flow 2 uses a brand-new account. If new exercises were added as per-user "custom" rather than code, the fresh account would NOT find them.

---

## Flow 0 — Per-week edit binding (the just-fixed bug) [PRIORITY]
Account: **WeekTest** (weektest_1780844@example.com / `Password123!`). NOTE: this account's data was wiped during pagination testing, so the "WeekBug Test" scenario must be re-created during setup: create a custom program with **4 weeks, 1 training day/wk** (Bench Press), then log **Week 2 Day 1 at 222 lb** while leaving Week 1 unlogged. (Setup, not recorded.) Then run the steps below.
Code: `logSlotIndex`/`programLogSlots` bind a log to `(week-1)*daysLen + dayIdx` (utils.ts:102-139); DayReview reads/writes via slots and stamps `week` (DayReview.tsx:51-55,136); Workout stamps `week` (Workout.tsx:124).
1. Programs → open **WeekBug Test** → ensure week selector shows **Week 1 / 4** → open Day 1 card.
   - **PASS:** Week 1 · Day 1 shows all sets **Weight = 0**, no set marked Done, button is "Save Workout" (not "Update Workout"). **FAIL (old bug):** shows 222 / Done / "Update Workout".
2. Back → advance to **Week 2 / 4** → open Day 1 card.
   - **PASS:** Week 2 · Day 1 shows set 1 **Weight = 222**, marked Done, button reads "Update Workout".
   - Net assertion: the Week 2 log did NOT bleed into Week 1. If Flow 0 step 1 shows 222, the fix is broken.

## Flow 1 — Per-user data survives a wiped device (no data loss)
Logged in as **Persist A**. Set distinctive values, wipe localStorage, re-login, verify restore.

1. **Settings → Theme color = pink (#ec4899).** Expect: app accents turn pink immediately.
2. **Create custom program "PERSIST PROG"** (accent gold), then open it and **Set as Active Program**. Expect: appears on Programs list with a **pencil** Custom icon; Home top card shows "Today · PERSIST PROG".
3. **Start its Day 1 workout, set first set Weight = 123, do NOT finish.** Navigate Home. Expect: Home card button reads **"Resume Workout"**.
4. **Nutrition (today):** add **1234** kcal, set water to **3** glasses, upload **1 photo**. Expect: calories ring shows 1234; Water 3/8; Photos **1 / 3** with a thumbnail.
5. **Profile/Progress:** add a body-weight entry **175**; create a Max tracker (e.g. Bench Press) with a record **200**. Expect: 175 lb shown; tracker lists 200.
6. **Favorite** the stock program **Strength Foundations**. Expect: star filled (gold) on its card.
7. **Simulate a fresh device:** open DevTools console once and run `localStorage.clear()` (no UI equivalent exists for wiping device storage — this is the only console use), then reload. Expect: app returns to logged-out /login.
8. **Log in as Persist A.** Verify EVERY value restored from server:
   - Theme accent is **pink**. (PASS if pink; FAIL if green/default)
   - Home shows **PERSIST PROG** active with **"Resume Workout"** and the in-progress set still **123**. (FAIL if "Start Workout" / 0 / no active program)
   - Nutrition today: **1234** kcal, Water **3/8**, Photos **1/3** with thumbnail. (FAIL if 0 / no photo)
   - Body weight **175**; Max tracker record **200**. (FAIL if empty)
   - Strength Foundations still **favorited**. (FAIL if unstarred)
   - Pass criteria: ALL of the above match. Any single reset-to-default = FAIL (data not server-persisted).

## Flow 2 — Every account gets the latest version & features; isolation
1. **Sign up Persist B** (fresh). Expect Home: "No active program", 0 workouts, **none** of Persist A's data (no PERSIST PROG, empty nutrition). (FAIL if any A data leaks across accounts)
2. **Exercises page:** search and confirm all three new exercises exist for this brand-new account: **"Weighted Pull-Up"**, **"Close Grip Lat Pulldown"**, **"Dumbbell Skullcrusher"**. (PASS if all 3 found; FAIL if missing → feature not shipped to all users)
3. **Spot-check latest UI exists for B:** Programs page shows icon-only **Program History** button; Nutrition page shows **Photos** + **Daily Goals above Photos**; Settings shows the 9 theme colors. (PASS if present)

## Flow 3 — Workout History & Body Weight pagination (newest feature)
Code: Progress.tsx limits both saved lists to `.slice(0,5)` and shows a "Show More" link only when `length > 5`; `/progress/history` (WorkoutHistory) renders `logs.slice(0,20)`; `/progress/weight` (BodyWeightHistory) renders all entries newest-first (ProgressHistory.tsx). Routes added in App.tsx:69-70.
Setup (not recorded/visible): log **6 workouts** (Strength Foundations Wk1 4 days + Wk2 2 days → 6 history entries) and pre-seed **8 dated body-weight entries** (no UI path for back-dated weigh-ins — console seed, disclosed in report).
1. **Profile → Workout History section.** Expect exactly **5** entries shown and a **"Show More"** link at the top-right of the section header. (FAIL if all 6 show, or no Show More.)
2. **Click "Show More" → `/progress/history`.** Expect header "Your 20 most recent finished workouts." and **all 6** entries listed (≤20). (FAIL if capped at 5 or navigates elsewhere.)
3. **Profile → Body Weight card.** Expect exactly **5** most-recent entries in the saved list + a **"Show More"** link. (FAIL if all 8 show, or no Show More.)
4. **Click "Show More" → `/progress/weight`.** Expect header "Every logged entry, newest first." and **all 8** entries, newest date first. (FAIL if capped at 5.)
5. **Negative check:** with ≤5 entries (e.g. fresh account), **no "Show More"** link appears in either section. (FAIL if link shows with ≤5 entries.)

## Out of scope / regression
- Detailed re-test of every individual UI tweak already shipped (icons-to-color, etc.) — only spot-checked.
- tester2@demo.com is a local-dev-only account (401 on prod); not used.
