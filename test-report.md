# Test Report — Per-user persistence & feature availability (NextRep)

**How I tested:** Ran the four-flow test plan against the **production** app (https://dist-bonpfmfm.devinapps.com, backend https://smellis-api.fly.dev) using real prod accounts, verifying that new-feature data is saved per-user on the server and that every account gets the latest features. Evidence is screenshots + text (no screen recording, per your preference).

**Devin session:** https://app.devin.ai/sessions/601f100a995e4891b6567761bb215803
**PR:** https://github.com/andersonmourot/stndrd-workout-app/pull/1

**Accounts used (prod, password `Password123!`):**
- WeekTest — `weektest_1780844@example.com` (Flow 0 + Flow 3 seeded data)
- Persist A — `persista_1780772@example.com` (Flow 1 + Flow 3 negative check)
- Persist B — fresh signup (Flow 2)

**Disclosure:** For Flow 3 I pre-seeded 6 workout logs and 8 dated body-weight entries via the app's own `PUT /api/data` endpoint, because the UI only allows one body-weight entry per calendar day (no path for back-dated weigh-ins). This is a testing convenience, not a code limitation — the same blob the app itself writes.

---

## Result summary

| Flow | What it proves | Result |
|------|----------------|--------|
| Flow 0 | Per-week edit binding (Wk2 log doesn't bleed into Wk1) | PASSED |
| Flow 1 | Per-user data survives a wiped device + re-login | PASSED |
| Flow 2 | Every account gets latest features; cross-account isolation | PASSED |
| Flow 3 | Workout History + Body Weight pagination (5 + Show More) | PASSED |

No failures. One thing worth noting (not a product bug) under Flow 3 below.

---

## Flow 0 — Per-week edit binding (the bug you reported)

Account: WeekTest, program "WeekBug Test" (4 weeks, Bench Press). Week 2 Day 1 was logged at **222 lb**; Week 1 left unlogged.

- **Expected:** Week 1 Day 1 stays empty (weights 0, no Done, "Save/Edit"); Week 2 Day 1 shows 222, marked Done, "Update Workout".
- **Observed:** Exactly that. Week 1 = all 0 / none Done; Week 2 = 222 / Done / "Update Workout". The Week 2 entry did **not** bleed into Week 1.
- **Result: PASSED.**

| Week 1 · Day 1 — empty (correct) | Week 2 · Day 1 — 222, Done |
|---|---|
| ![Flow 0 Week 1 empty](https://app.devin.ai/attachments/1a98e7b7-2304-45fc-8837-3e8ad2c2e785/screenshot_7ce9673ca1a249239b699323b2a062f1.png) | ![Flow 0 Week 2 222](https://app.devin.ai/attachments/d851e3df-8d70-461b-ad43-ffbce1cbc80f/screenshot_88f113adbac84e868e338aa333e55834.png) |

---

## Flow 1 — Per-user data survives a wiped device (no data loss)

Account: Persist A. Set 7 distinctive values, then ran `localStorage.clear()` (only console use — there's no UI to wipe device storage) + reload + re-login.

- **Expected:** every value restored from the server after the wipe.
- **Observed (all restored):** pink theme accent; PERSIST PROG active with an in-progress workout (123 lb) showing "Resume Workout"; Nutrition 1234 kcal / Water 3/8 / 1 photo; body weight 175; Max tracker 200; Strength Foundations favorited. Nothing reset to default.
- **Result: PASSED.** Confirms all state is saved per-user on the backend, not just on the device.

---

## Flow 2 — Every account gets the latest version & features; isolation

Account: Persist B (brand-new signup).

- **Isolation:** new account showed no active program, 0 workouts, none of Persist A's data. No cross-account leakage. **PASSED.**
- **New exercises present for a fresh account:** Weighted Pull-Up, Close Grip Lat Pulldown, Dumbbell Skullcrusher all found (they ship in code, so every account has them). **PASSED.**
- **Latest UI present:** icon-only Program History button, Nutrition Photos with Daily Goals above Photos, full theme-color set in Settings. **PASSED.**

---

## Flow 3 — Workout History & Body Weight pagination

Account: WeekTest, seeded with 6 workout logs and 8 body-weight entries.

- **Body Weight card shows exactly the 5 most recent + "Show More"** (Jun 7→Jun 3; current 175 with "-6 since start"). **PASSED.**
- **Workout History section shows exactly 5 + "Show More"** (HTML confirmed 5 of the 6 logs listed). **PASSED.**
- **"Show More" → `/progress/history`** shows header "Your 20 most recent finished workouts." with **all 6** entries. **PASSED.**
- **"Show More" → `/progress/weight`** shows header "Every logged entry, newest first." with **all 8** entries, newest first. **PASSED.**
- **Negative check:** Persist A (1 body-weight entry, 0 workouts) shows **no** "Show More" on either section. **PASSED.**

| Body Weight — 5 most recent + Show More | Body Weight full page — all 8, newest first |
|---|---|
| ![BW 5 recent](https://app.devin.ai/attachments/f525d144-0ca7-496e-bd9d-bdf40f50c34a/screenshot_941d2dafffd54cb6a2866a0beb5bcf1a.png) | ![BW full 8](https://app.devin.ai/attachments/e0e2ad52-631c-48d3-8cee-8319fec739b1/screenshot_2ac11d7d191b4fafba97fbe44e3655e5.png) |

| Workout History full page — all 6 (≤20) | Negative check — ≤5 entries, no Show More |
|---|---|
| ![History full 6](https://app.devin.ai/attachments/3c82d02a-0a7a-4b1b-b2a2-f0c985e6b1eb/screenshot_98891e7213ff4a7bbb41a29cff8e588e.png) | ![No Show More](https://app.devin.ai/attachments/c271eae0-39ed-4dbd-b8d8-681f5f0493f4/screenshot_dcea852cd6554895a88ea02708f2b061.png) |

**Note (not a product bug):** On first load my body-weight seed displayed the 5 *oldest* instead of newest. Root cause was my seed array order — the app's UI always writes body-weight sorted oldest→newest and the list does `reverse().slice(0,5)` to show the 5 newest. After re-seeding in the same order the app produces, the card correctly showed the 5 most recent. Real in-app entries are unaffected; this was purely a seeding artifact I corrected before recording the result above.

---

## Out of scope
- Detailed re-test of every individual UI tweak already shipped (icon colors, etc.) — only spot-checked.
- iPhone safe-area bottom-gap fix — can't reproduce iOS safe-areas in a desktop browser; needs your confirmation on-device.
