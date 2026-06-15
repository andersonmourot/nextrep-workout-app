# SMELLIS — Feature & Persistence Test Plan

Live frontend: https://dist-bonpfmfm.devinapps.com · Backend: https://smellis-api.fly.dev

Accounts (created in setup):
- **Account A** — admin tester (email in ADMIN_EMAILS) — `aaron.smellis1780682398@example.com`
- **Account B** — sharer / non-admin — `bella.smellis1780682398@example.com` (has shared custom exercise "Bulgarian Split Squat"; NO shared program)

---

## T1 — Shared exercise appears in search result card (the reported bug)
Code: People.tsx SharedContent renders an Exercises section when `exerciseCount > 0` (lines 226-232, 312-336); search card expands SharedContent.
- **Steps:** As A, go to Search → search "Bella" → expand her card.
- **PASS:** Card subtitle reflects exercises; expanding shows an **Exercises** section containing "Bulgarian Split Squat" with an **Add** button. (Bug fixed.)
- **FAIL:** Exercise missing / only programs shown.

## T2 — Empty shared sections are blank (no "0 programs"/"No shared content")
Code: subtitle parts only built from non-zero counts; Programs section hidden when none (line 260).
- **PASS:** B has NO shared program → no "Programs" section and no "0 programs" text anywhere on her card; only the Exercises section shows.
- **FAIL:** Any "0 programs" / "No shared content" literal text shown.

## T3 — Add shared exercise to my library
Code: addExerciseToMine copies with `shared:false` (lines 250-254).
- **Steps:** A clicks **Add** on Bulgarian Split Squat.
- **PASS:** Button switches to "Added"; exercise now appears in A's Exercises list (with Custom badge).
- **FAIL:** No-op or error.

## T4 — Favorite up to 3, pinned to top, persists
Code: sortedFollowing pins favoriteUserIds (lines 105-110); MAX_FAVORITES cap (line 111, store toggle).
- **Steps:** A follows B (and ideally another user) → star B as favorite.
- **PASS:** Favorited user moves to top of Following; star filled. Survives reload.
- **FAIL:** No pin, or cap not enforced, or lost on reload.

## T5 — Profile body-weight date has NO weekday
Code: formatDateLong drops weekday (utils.ts:20-26).
- **Steps:** A → Profile → add a body weight entry.
- **PASS:** Saved date shows `Mon D, YYYY` style (e.g. "Jun 2, 2026"), NO "Thu"/weekday.
- **FAIL:** Weekday present.

## T6 — Nutrition page: log entry persists across reload
Code: Nutrition page writes nutritionLog keyed by ISO date; snapshot syncs to backend.
- **Steps:** A → Profile → Nutrition button → enter calories, protein/carbs/fat, water.
- **PASS:** Values display + ring/bars update; after hard reload values restore.
- **FAIL:** Values lost on reload.

## T7 — Nutrition goals editable + persist
- **Steps:** Edit a goal (e.g. calories goal) → save.
- **PASS:** New goal reflected in ring target; survives reload.
- **FAIL:** Reverts to default.

## T8 — Max Tracker: create tracker + record, shows latest, persists
Code: MaxTracker list shows latest weight/reps; addMaxRecord dedupes by name.
- **Steps:** A → Profile → Max Tracker → create "Bench Press" with weight+reps.
- **PASS:** Card shows name + latest weight/reps + date; survives reload.
- **FAIL:** Not saved.

## T9 — Max Tracker detail: history + trend chart; add 2nd record
- **Steps:** Open the tracker → add a second dated record (higher weight).
- **PASS:** History lists both records (reverse date), trend chart renders a line; list card shows newest as latest.
- **FAIL:** Chart absent / history wrong.

## T10 — Server-side persistence proof (re-login on fresh state)
Code: snapshot() includes favoriteUserIds, nutritionLog, nutritionGoals, maxTrackers; load merges `{...defaults, ...saved}`.
- **Steps:** Log out of A → log back in (clears local in-memory, rehydrates from backend).
- **PASS:** Favorites, nutrition entry+goals, max trackers all still present.
- **FAIL:** Any data missing after re-login → not server-persisted.

## T11 — Admin Users page (admin only; no passwords)
Code: Settings shows Users card if `account?.is_admin`; AdminUsers fetches /api/admin/users; backend 403 for non-admin.
- **Steps:** A → Settings → Users → view list.
- **PASS:** Settings shows **Users** card; page lists all registered users with name, email, join date (no weekday); **NO password column/field**; includes A and B.
- **FAIL:** Passwords shown, or page errors.

## T12 — Non-admin has NO Users button & is blocked
- **Steps:** Log in as B → Settings.
- **PASS:** No "Users" card in B's Settings; navigating directly to /admin/users redirects/blocks (no data).
- **FAIL:** B sees Users button or the user list.

## T13 — Backward compatibility (existing/new account loads latest build)
Code: single static deploy; defaults backfill missing fields.
- **PASS:** A & B (new accounts) load Search/Profile nav, Nutrition, Max Tracker, all features with no errors; new fields default cleanly (no crash for accounts lacking them).
- **FAIL:** Crash or missing feature.
