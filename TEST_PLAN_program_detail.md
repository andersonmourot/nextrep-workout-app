# Test Plan — Program detail "..." menu, clickable day review, post-edit redirect, Weighted Pull-Up

Env: local dev — frontend http://localhost:5173 against local backend :8000. Logged in as a test account with one **custom** program **set as active** (so Edit/Duplicate/Reset/Delete all apply).

## Test 1 — "..." collapses the four action buttons
1. Open the active custom program's detail page (`/programs/:id`).
- PASS: Below "Active Program", a single button showing only a "..." (horizontal dots) icon is visible. Edit / Duplicate / Reset / Delete are NOT visible.
- FAIL: All four text buttons render directly (old behavior).
2. Click the "..." button.
- PASS: The "..." is replaced in the same spot by the row of buttons: **Edit, Duplicate, Reset, Delete** (Reset shown because active, all shown because custom).
- FAIL: Nothing changes, or only some buttons appear.

## Test 2 — Clickable day card opens day review + back arrow + add data
1. Scroll to "The Split". Click the **top/left area of Day 1's card** (the day name region, not the "Start" button).
- PASS: Navigates to `/programs/:id/day/0`. Header shows a back **arrow icon only** (no "Back" text), an eyebrow "Week 1 · Day 1", the day name, and exercise cards with Set/Weight/Reps/Done rows.
- FAIL: Stays on detail, or starts a live workout (timer visible), or shows a worded back button.
2. On an exercise, set Weight and Reps via the steppers and tap the round **Done** check on one set. A "Save Workout" button appears; click it.
- PASS: Button text becomes "Saved".
- FAIL: No save button appears, or it errors.
3. Click the back **arrow** (top-left, icon only).
- PASS: Returns to `/programs/:id` (program detail). The day just logged now shows a green "Done" badge.
- FAIL: Goes elsewhere, or the day shows no Done badge.
4. Click that same (now completed) day's card again.
- PASS: DayReview reopens pre-filled with the weight/reps just saved (not zeros), and the button reads "Update Workout".
- FAIL: Opens with empty/zero sets (data not loaded).

## Test 3 — Post-edit redirect to program detail
1. From the program detail, open "..." → **Edit**. Change the program name (append " X"). Save.
- PASS: Lands on `/programs/:id` (that program's **detail** page), showing the updated name — NOT the main `/programs` list.
- FAIL: Lands on the main Programs list.

## Test 4 — Weighted Pull-Up exists (regression-adjacent, quick)
1. Go to Exercises, search "Weighted".
- PASS: A "Weighted Pull-Up" card appears (distinct from "Pull-Up").
- FAIL: No such card.
