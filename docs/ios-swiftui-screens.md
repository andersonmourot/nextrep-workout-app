# NextRep — SwiftUI screen-by-screen spec

Companion to `ios-swiftui-handoff.md` (API + data model). This doc maps the
**web app's screens** to SwiftUI so the native build matches the existing app
1:1 in layout, behavior, and styling.

Build the screens in the order below. Each section is self-contained and ends
with a paste-ready prompt for the CLI. Apply the shared design system from
`Theme.swift` (see the handoff thread / "Design system" section here) to every
screen — dark surfaces, green accent `#355E3B`, Oswald display font for
titles, Inter for body.

---

## 0. Foundations (do these once, before any screen)

### Design tokens (dark theme)
| Token | Hex | Use |
|---|---|---|
| `bg` | `#08080A` | app background / screen edges |
| `surface` | `#141417` | cards |
| `surface2` | `#1B1B1F` | ghost buttons, chips, icon buttons |
| `surface3` | `#26262B` | hover/pressed |
| `inputBg` | `#0D0D10` | text fields |
| `text` | `#F4F4F5` | primary text |
| `textDim` | `#A1A1AA` | secondary text |
| `textFaint` | `#71717A` | tertiary / placeholders / eyebrow |
| `accent` | `#355E3B` | brand green (per-program `accent` overrides locally) |
| `accentLt` | `#4C8A55` | hover/glow |
| `accentDk` | `#284A30` | pressed |

- **Fonts:** titles use **Oswald SemiBold**, uppercase, wide letter-spacing
  (`heading` in web = `font-display uppercase tracking-wide`). Body uses
  **Inter**. Eyebrow labels = Inter 11pt, uppercase, tracking ~2, color
  `accent.opacity(0.8)`.
- **Radii:** cards 16pt, buttons/inputs/chips 12pt (chips are full pills).
- **Card:** `surface` fill, 1px `white.opacity(0.05)` border, soft drop shadow
  (`black.opacity(0.6)`, radius 12, y 8). Use `.cardStyle()`.
- **Container:** content is centered, max width ~448pt, 16pt horizontal padding
  (web `.container-app` = `max-w-md px-4`). On iPhone that's just full-width
  with 16pt insets.
- **Background flourish:** a faint green radial glow at the top of the screen
  (`RadialGradient` of `accent.opacity(0.12)` → clear, centered above the top
  edge). Put it behind all content in the root.

### Buttons (match `.btn-*` web classes)
- **Primary** (`btn-gold`): `accent` fill, white semibold text, 12pt radius,
  ~16h/12v padding, full width by default, scale 0.98 + opacity on press.
- **Ghost** (`btn-ghost`): `surface2` fill, `text` color, 1px white/5 border.
- **Outline** (`btn-outline`): clear fill, `accent.opacity(0.4)` border, accent
  text, faint accent tint on press. Used for small "Start/Resume" buttons.
- **Chip:** pill, `surface2` fill, 1px white/10 border, 11pt `textDim`.

### Navigation shell — bottom tab bar
Five tabs, exactly these, in this order (web `BottomNav`):
| Tab | Icon (SF Symbol) | Destination |
|---|---|---|
| Home | `house` | Dashboard |
| Programs | `square.grid.2x2` | Programs list |
| Timer | `timer` | Standalone Timer |
| Search | `magnifyingglass` | People/Search |
| Profile | `person` | Progress/Profile |

Active tab tints `accent` with a soft glow on the icon; inactive is `textFaint`.
Tab bar background is `#0D0D10` at ~90% opacity with a top hairline border and
respects the bottom safe area. Use a `TabView`; each tab hosts its own
`NavigationStack` so back-navigation is per-tab.

### Data the screens read (from the `/api/data` blob + `/api/catalog`)
- **All programs** = built-in catalog programs (from `GET /api/catalog`) merged
  with the user's `customPrograms`, minus `hiddenProgramIds`, minus
  `trashedPrograms`. (Mirror the web `useAllPrograms` selector.)
- **All exercises** = catalog `exercises` + `customExercises`.
- `activeProgramId`, `favoriteProgramIds` (max 5), `logs` (`WorkoutLog[]`),
  `unit` ("lb"/"kg"), `programAnchors` (per-program start dates),
  `activeWorkout` (the live session), `exerciseNotes`/`exerciseSubheaders`
  (private maps keyed by exerciseId).
- Helpers to port from `src/lib/utils.ts`: `programRun` (current week/day +
  isComplete), `computeStreak`, `workoutsThisWeek`, `resolveProgramDay`
  (applies per-week overrides), `supersetGroups` (group consecutive exercises
  sharing `groupId`), `exerciseLabel` (custom `name` ?? library name).

---

## 1. Dashboard (Home tab) — `src/pages/Dashboard.tsx`

Vertical scroll, ~24pt gaps between sections.

1. **Header:** eyebrow = time-of-day greeting ("Good morning" etc.), then the
   user's `name` as a large Oswald title.
2. **Today's workout card** (the hero). Three states:
   - **Active program with a next day:** card tinted with the program's
     `accent` (top→down gradient). Top row: eyebrow `Today · {program.name}` and
     a chip `Week {w} · Day {d}`. Big title = next day's `name`, subtitle =
     `focus`. Then up to 4 exercise chips (`exerciseLabel`), with a `+N more`
     chip if longer. Full-width primary button: **Resume Workout** if an
     `activeWorkout` exists for this program, else **Start Workout** (calls
     `startWorkout(programId, dayId, week)` then navigates to the Workout
     screen). Tapping the card body (not the button) opens Program detail.
   - **Program complete:** title "Program complete", body about finishing all
     weeks, primary button "View Program".
   - **No active program:** card "No active program" + body + primary button
     "Browse Programs" → Programs tab.
3. **Stats row** (3 equal cards):
   - Streak — flame icon, `{streak}`, suffix "days".
   - Week ring — a circular `ProgressRing` (value = `weekCount / weekTarget`,
     accent stroke) with `weekCount` in the center, caption `of {target}/wk`.
   - Workouts — dumbbell icon, `{logs.count}`, suffix "total".
   Stat cards: centered, accent-colored icon, big Oswald number.
4. **Recent Activity:** section header "Recent Activity" + a "View all" link
   (→ Profile/Progress) shown only when there are logs. Then the 3 most recent
   `logs` as rows: left = `dayName` (semibold) + `{programName} · {date}`;
   right = trending-up icon + `{round(totalVolume)} {unit}` in accent. Empty
   state: a card "Your completed workouts will show up here."

> CLI prompt — "Build the Dashboard (Home tab) per docs/ios-swiftui-screens.md
> §1. Use the shared Theme and components. Read activeProgramId, the resolved
> active program, programAnchors, logs, unit, and activeWorkout from the store.
> Compute next day via a ported `programRun`, streak via `computeStreak`, and
> this-week count via `workoutsThisWeek`. Implement the three hero states, the
> 3-stat row with a circular progress ring, and the recent-activity list with
> empty state. Wire Start/Resume to startWorkout + navigate to the Workout
> screen, and the card body to Program detail."

---

## 2. Programs list (Programs tab) — `src/pages/Programs.tsx`

1. **Header row:** title "Programs" (Oswald) on the left; on the right a small
   primary `+` button → Program editor (new). (A "manage"/gear affordance can
   come later — the manage/hide/trash flows are Phase 2.)
2. **Search field:** full-width, leading magnifying-glass icon, placeholder
   "Search". Filters by name, summary, coach, category, level, and
   "{daysPerWeek} day(s)".
3. **Category filter chips** (horizontal scroll): `All, Bodybuilding, Strength,
   HIIT, Powerlifting, Functional, Bodyweight`. Selected chip = `accent` fill +
   white text; others = `surface2` + white/10 border.
4. **Program cards** (vertical list). Ordering: active program first, then
   favorites (in favorite order), then the rest. Each card:
   - Background: subtle 150° gradient from `accent` (low alpha) to clear.
   - Top row: eyebrow `{category} · {level}` in the program's accent, plus small
     round badges when applicable: pencil (custom), check-circle (active), star
     (favorite).
   - Title = `name` (Oswald, ~xl). Subtitle = `summary` (`textDim`).
   - Meta row: clock `{durationWeeks} weeks` · dumbbell `{daysPerWeek} days /
     week`.
   - Whole card taps → Program detail.

(Defer the "manage mode" delete/hide overlay, the Hidden list, and the Trash
list to a later pass — note them as TODO but don't block the core list.)

> CLI prompt — "Build the Programs list (Programs tab) per
> docs/ios-swiftui-screens.md §2. Source the list from the merged catalog +
> customPrograms (ported `useAllPrograms`), with search + category filtering and
> the active/favorites-first ordering. Render the gradient program cards with
> eyebrow, badges, title, summary, and meta row, tapping into Program detail.
> Add the header + `+` button to the Program editor (stub the editor for now).
> Skip manage/hidden/trash modes this pass."

---

## 3. Program detail — `src/pages/ProgramDetail.tsx`

Scroll view, accent = the program's `accent` for this screen.

1. **Back button** (chevron + "Back") → Programs list.
2. **Hero card** (gradient from accent → `surface`):
   - Favorite star button top-right (toggles `favoriteProgramIds`, max 5;
     disabled when full and not already a favorite).
   - Eyebrow `{category} · {level}`; a "Custom" or "Following" pill when
     applicable.
   - Title `name` (Oswald 3xl), `description` below.
   - 3 meta tiles: Weeks `{durationWeeks}`, Days/wk `{daysPerWeek}`, Days
     `{days.count}`.
   - Primary button: **Set as Active Program** (disabled, shows "Active
     Program" with a check, when already active).
   - When active & complete: a tinted panel "Program complete" with a "Save to
     History & Reset" action (confirm inline) — can be a later pass.
3. **Week pager** (only if `durationWeeks > 1`): a row to page between weeks
   (chevrons + "Week N"), defaulting to the current week from `programRun`.
4. **Day list:** for each day in the selected week (`resolveProgramDay`):
   - Card. If it's the "up next" day, give it an accent border + glow.
   - Header (tap → Day review): eyebrow `Day {i+1}` with a green "Done" check if
     that week+day is logged, or "Up next" in accent; title = day `name`;
     subtitle = `focus`. Right: small **outline** button "Start" (or "Resume"
     if this exact day/week is the live session) → `handleStartDay`.
   - Below: a divided list of the day's exercises. Each row: `exerciseLabel`
     (semibold) + a meta line — if that exercise is logged show the done
     summary `weight×reps · …` in green, else `{sets} × {reps} · {restSec}s
     rest`. Rows with a resolvable library exercise are tappable → Exercise
     detail (chevron at trailing edge).
5. **Footer actions** (can be a later pass): Edit (custom only), Duplicate,
   Delete.

`handleStartDay(dayId, week)`: if no active program or it's this program, call
`startWorkout` and navigate to Workout. If a *different* active program has
saved progress, confirm the switch first (web shows a `pendingStart` confirm).

> CLI prompt — "Build Program detail per docs/ios-swiftui-screens.md §3. Hero
> card with favorite toggle, meta tiles, and Set-as-Active button; an optional
> week pager; and the day list using `resolveProgramDay`, with up-next
> highlighting, per-day Start/Resume buttons (→ startWorkout + Workout screen),
> and exercise rows showing logged summaries or set/rep/rest, tapping into
> Exercise detail. Defer Edit/Duplicate/Delete and the complete/reset panel."

---

## 4. Active Workout + rest timer — `src/pages/Workout.tsx` (the core loop)

This is a full-screen flow (not inside the tab bar chrome; the bottom rest bar
sits above where the tab bar would be).

**Resolve:** `program` from `activeWorkout.programId`; `day` via
`resolveProgramDay(program, dayLocalIdx, activeWorkout.week ?? 1)`. Group the
day's exercises with `supersetGroups`. The `activeWorkout.sets: SetLog[][]` is
aligned 1:1 with `day.exercises`.

1. **Sticky top bar:** left = close `X` (navigates to Program detail; the
   session stays live so entered data is kept). Center = day `name` (Oswald) +
   `program.name`. Right = a pill with a timer icon + elapsed clock
   (`mm:ss`, derived from `startedAt`). Under the bar: a thin progress bar =
   completed sets / total sets, accent fill.
2. **Exercise cards** (one per group):
   - **Standalone exercise card:** eyebrow `Exercise {i+1} of {n}`; title
     `exerciseLabel`; subtitle `{sets} sets × {reps} reps`. Trailing controls:
     a **cue button** + **notes button** (see below) + an info button (→
     Exercise detail) when it maps to a library exercise. If `pe.notes` exists,
     a small accent-tinted note line. Then the **cue subheader** if set.
     - **Sets table:** header row `Set | Weight ({unit}) | Reps | Done`. One
       **SetRow** per set: a small set-number badge, a numeric Weight field
       (decimal), a numeric Reps field, and a Done toggle (checkbox-style
       square; filled accent when done). Completed rows get an accent-tinted
       background + border.
   - **Superset/triset card:** accent-bordered container with header `Superset
     {label} · no rest between` and `{rounds} rounds`. A legend lists each
     member once (badge `A1`,`A2`,… + name + cue/notes/info). Then round-by-
     round rows: for each round, a `Weight | Reps | Done` row per member tagged
     `A1/A2/…`. Only the **last member of a round** triggers rest.
3. **Finish button:** full-width primary "Finish Workout" at the end of the
   list → builds a `WorkoutLog` (keep sets that are completed OR have weight>0,
   mark them done; sum `totalVolume = Σ weight*reps`), calls `addLog`, and shows
   the **Summary** screen.
4. **Rest timer (floating bar)** — shown only while resting, pinned to the
   bottom (above where the tab bar sits). Left: eyebrow "Rest" + big accent
   `mm:ss` (tabular). Right: ghost **+15s** and primary **Skip** buttons. Below:
   a thin accent progress bar = `remaining / restTotal`.
   - **Behavior:** completing the last set of a round with `restSec > 0` starts
     rest (`restEndsAt = now + restSec*1000`, `restTotal = restSec`). A 1s timer
     updates the clocks; when rest hits 0 on its own, **play the bell sound**
     and clear rest. **Skip** clears rest silently (no bell). **+15s** extends
     both `restEndsAt` and `restTotal`.
   - This is where native wins: schedule the bell so it fires even when the app
     is backgrounded/locked (background audio + a local notification fallback) —
     the thing the web app can't do. Wire it through an `AVAudioSession`
     configured for background playback.
5. **Summary screen** (after Finish): centered check badge, eyebrow "Workout
   Complete", day name + program name, 3 stat cards (Time, Sets, Vol), and a
   primary "Done" → `endWorkout()` + back to Dashboard.

**SetLog** = `{ weight: Double, reps: Int, completed: Bool }`. The numeric
fields should show empty (placeholder "0") when the value is 0, not a literal
unerasable 0 (mirror the web `NumberField`).

> CLI prompt — "Build the Active Workout screen per
> docs/ios-swiftui-screens.md §4 — the core loop. Resolve program/day/sets from
> activeWorkout, group supersets via `supersetGroups`, render standalone and
> superset cards with the Set/Weight/Reps/Done table, a sticky header with
> elapsed clock + progress bar, and the floating rest-timer bar (+15s / Skip /
> auto-bell). Completing the last set of a round starts rest; finishing builds a
> WorkoutLog (sets completed-or-weighted, totalVolume = Σ weight*reps), calls
> addLog, and shows the Summary screen. Configure AVAudioSession for background
> playback so the rest-end bell fires when the app is backgrounded or the phone
> is locked, with a local-notification fallback."

---

## 5. Per-exercise cue + notes (shared controls used in §3/§4)

These appear as two small trailing icon-buttons on each exercise (in Workout and
the day views), matching the recently-shipped web behavior:

- **Notes** (pencil icon): opens a sheet to view/edit a **private** free-text
  note for that exercise (`exerciseNotes[exerciseId]`). The button does **not**
  highlight when a note exists.
- **Cue** (list icon): when there is **no cue yet**, show this button; tapping
  opens an inline editor to add a short cue. Once a cue exists
  (`exerciseSubheaders[exerciseId]`), the button disappears and the cue renders
  as a green left-bar line under the exercise title (tap the line to edit).
- Both `exerciseNotes` and `exerciseSubheaders` are **private per-user** and are
  never shared when a program/exercise is shared. Persist them in the `/api/data`
  blob like the web app.

> CLI prompt — "Add the per-exercise Notes (pencil) and Cue (list) controls per
> docs/ios-swiftui-screens.md §5, backed by the private exerciseNotes and
> exerciseSubheaders maps in the data blob. No-cue → show a cue button; cue set
> → render a green left-bar line under the title (tap to edit) and hide the
> button. Notes live behind the pencil with no highlight."

---

# Batch 2 — Day review/edit, Exercises library, Exercise detail

These build on §0 foundations and the §5 cue/notes controls. Reachable from
Program detail (§3) and the Workout screen (§4).

---

## 6. Day review + Day edit — `src/pages/DayReview.tsx`

Reached by tapping a day card in Program detail. The route carries a **0-based
global day index** across weeks: `globalIdx`. Derive `dayLocalIdx = globalIdx %
days.count` and `weekNum = floor(globalIdx / days.count) + 1`, then resolve the
plan with `resolveProgramDay(program, dayLocalIdx, weekNum)`.

This screen has **two modes**: a logging view (the default) and an inline plan
editor (only for editable custom programs).

### 6a. Logging view (default)
1. **Back button** (icon-only arrow): pop the nav stack if possible, else go to
   the program detail.
2. **Header:** eyebrow `Week {weekNum} · Day {dayLocalIdx+1}` in the program's
   accent; title = day `name` (Oswald); subtitle = `focus`. If the program is
   editable (`isCustom && (isOwner || collaborative)`), show a small accent
   **Edit** button on the right (enters edit mode — 6b).
3. **Set state:** local `SetLog[][]`, pre-filled from the existing log for this
   exact week+day slot (`programLogSlots(program, logs, anchor)[globalIdx]`) if
   present, otherwise from the day template (each exercise → `sets` rows with
   `weight 0`, `reps = parseReps(reps)`, `completed false`). `parseReps` =
   leading integer of the rep string ("8-12" → 8).
4. **Exercise cards** (one per exercise): eyebrow `Exercise {i+1} of {n}`, title
   `exerciseLabel`, subtitle `{sets} sets × {reps} reps`, trailing cue + notes +
   info controls (§5), then the cue subheader. Then a `Set | Weight ({unit}) |
   Reps | Done` table. **Difference from §4:** each weight/reps cell here is a
   **Stepper** (a −/+ control around the number; weight step 5, reps step 1),
   not a free-type field. Done toggle + completed-row tint same as §4.
5. **Save button** (only when at least one set is completed, hidden in edit
   mode): full-width primary. Label = "Save Workout" (or "Update Workout" if a
   log already exists; "Saved" + disabled right after saving). On save: build a
   `WorkoutLog` keeping only **completed** sets (note: unlike §4 Finish, this
   does not auto-include weighted-but-untapped sets), `totalVolume = Σ
   weight*reps`, bind it to this week+day slot via `addLog`.

### 6b. Edit-this-day mode (custom programs only)
A card titled **"Edit this day"** with a subtitle explaining scope: Week 1 edits
the base plan for the whole program; Week N>1 edits "from Week {N} onward"
(earlier weeks keep the current plan). For each exercise in the `draft`:
- A text field for the exercise name (type-ahead to the library; free text =
  custom exercise). A small caption under it: `{primaryMuscle} · {equipment}` or
  "Custom exercise".
- Up/down reorder buttons (disabled at ends) and a cue button (§5) + a trash
  button (disabled when only one exercise remains).
- A 3-up row of fields: **Sets** (numeric), **Reps** (text, e.g. "8-12"),
  **Rest** (numeric seconds).
- An "add exercise" dashed outline button at the bottom.
- Footer: **Cancel** (ghost) and **Save** (primary). Validation: at least one
  exercise; every exercise must have a name. On save, apply a **per-week
  override**: `withDayOverride(program, day.id, weekNum, draft)` then
  `updateProgram`; if the program is shared/owned, also push via
  `apiUpsertProgram`. Rebuild the local set state from the new plan and exit
  edit mode.

> CLI prompt — "Build Day review + Day edit per docs/ios-swiftui-screens.md §6.
> Parse the global day index into local day + week, resolve the plan with
> `resolveProgramDay`. Logging view: header with Week/Day eyebrow and an Edit
> button for editable custom programs; per-exercise cards with cue/notes/info
> and a Set|Weight|Reps|Done table using Stepper (−/+) controls (weight step 5,
> reps step 1); a Save/Update button (visible once a set is completed) that
> builds a WorkoutLog from completed sets bound to this week+day slot via addLog.
> Edit mode (custom only): an editable draft of the day's exercises (name with
> library type-ahead, reorder, cue, delete, Sets/Reps/Rest fields, add-exercise)
> that saves via a per-week override (`withDayOverride` + updateProgram, and
> apiUpsertProgram when shared), with the Week-1-vs-later scope note and
> validation. Use the shared Theme. Build and run in the Simulator and show me."

---

## 7. Exercises library — `src/pages/Exercises.tsx`

A flat, searchable list of all exercises (Search tab → later, but reachable now
from Program editor and exercise pickers). Two routes use the same page; one
shows a Back button.

1. **Header:** title "Exercises" (Oswald). Right side: a manage toggle
   (gear → "Done") and a primary `+` button (New exercise → opens the Exercise
   form sheet, §7a). When managing and there are hidden/trashed items, show
   "Hidden (n)" and a trash count button.
2. **Search field** (leading icon, placeholder "Search").
3. **Filter chips** (horizontal scroll): `All, Custom,` then the muscle list
   (Chest, Back, Shoulders, Biceps, Triceps, Quads, Hamstrings, Glutes, Calves,
   Core, Forearms, Full Body). Selected = accent fill + white; "Custom" filters
   to user-created exercises. Selected-state styling as in §2.
4. **Count line:** `{n} exercises`.
5. **List source:** custom exercises (those whose name isn't a built-in) +
   built-ins (with any local override applied), minus hidden, minus trashed.
   Each row is a card: name (semibold) with a "Custom" pill when applicable; a
   chip row `{primaryMuscle}` (accent) · `{equipment}` · `{difficulty}`. Tap →
   Exercise detail (§8).
6. **Manage mode:** each row gets an inline delete/hide affordance with a
   confirm (custom → delete to Trash; built-in → hide). Plus a Hidden list and a
   Trash list (restore / purge). This can be a later pass — ship the list +
   search + New first.

### 7a. Exercise form sheet (New / Edit) — `ExerciseModal`
A sheet with fields: **Name**; **Primary muscle** (picker); **Equipment**
(picker: Barbell, Dumbbell, Machine, Cable, Bodyweight, Kettlebell, Bands);
**Difficulty** (Beginner/Intermediate/Advanced); **Secondary muscles**
(multi-select chips, excluding the primary); **Instructions** (multiline, one
step per line); **Coaching cues/tips** (multiline, one per line); optional
**Photos** (up to two). Save creates/updates a custom exercise (or a local
override of a built-in). Title = "New Exercise" / "Edit Exercise".

> CLI prompt — "Build the Exercises library per docs/ios-swiftui-screens.md §7.
> Header with title, a New (+) button opening the Exercise form sheet, and a
> manage toggle; a search field; filter chips (All, Custom, then the 12 muscles)
> with accent selection; a '{n} exercises' count; and the exercise list (custom
> non-duplicates + built-ins with overrides, minus hidden/trashed) as cards with
> name, optional Custom pill, and primaryMuscle/equipment/difficulty chips,
> tapping into Exercise detail. Build the Exercise form sheet (§7a) with Name,
> Primary muscle, Equipment, Difficulty, Secondary-muscle multi-select,
> Instructions (one per line), Tips (one per line), and optional photos, saving
> as a custom exercise / override. Defer manage/hidden/trash. Use the shared
> Theme. Build and run in the Simulator and show me."

---

## 8. Exercise detail — `src/pages/ExerciseDetail.tsx`

Resolve the exercise as: custom exercise by id, else a local override, else the
built-in from the catalog. If missing, show a "not found" + back link.

1. **Top bar:** Back (arrow) on the left; on the right an **Edit** button (opens
   the §7a form) and a **Delete** button (two-tap confirm: Delete → Confirm /
   Cancel; deleting returns to the library).
2. **Title block:** eyebrow `{primaryMuscle}`; title `name` (Oswald 3xl); a chip
   row `{equipment}` · `{difficulty}` · each secondary muscle.
3. **Notes section:** a multiline text field bound to `exerciseNotes[id]` — the
   **same private note** shown via the §5 pencil everywhere this exercise
   appears (editing here updates those and vice versa). Placeholder: "Add notes
   for this exercise — form cues, weights to try, reminders…".
4. **Muscle visual:** a card with a soft accent radial-gradient circle showing
   the primary muscle name.
5. **How to perform:** a numbered list of `instructions` (accent number badges).
6. **Coaching cues:** `tips` as cards with a lightbulb icon.
7. **Photos:** a 2-column grid of `photos` if any.

> CLI prompt — "Build Exercise detail per docs/ios-swiftui-screens.md §8.
> Resolve the exercise (custom → override → catalog). Top bar with Back, an Edit
> button (opens the §7a form sheet) and a two-tap Delete confirm (returns to the
> library). Title block with primaryMuscle eyebrow, name, and
> equipment/difficulty/secondary-muscle chips. A Notes text field bound to the
> shared private exerciseNotes[id]. A muscle-visual card, a numbered How-to list
> from instructions, a Coaching-cues list from tips (lightbulb icon), and a
> 2-column photo grid when present. Use the shared Theme. Build and run in the
> Simulator and show me."

---

# Batch 3 — Program editor + standalone Timer

The Program editor is the largest single screen in the app; the Timer is a
self-contained tool (its own tab). Both reuse §0 foundations and §5 cue control.

---

## 9. Program editor — `src/pages/ProgramEditor.tsx`

Create or edit a program. Reached from the Programs list `+` (new), Program
detail Edit (existing), and — in **catalog mode** — the Admin Catalog page
(edits the shared built-in catalog instead of a personal program; admin only).

**State** mirrors the `Program` fields: `name`, `category`, `level`, `coach`,
`durationWeeks`, `daysPerWeek`, `accent`, `summary`, `description`,
`collaborative`, `days: ProgramDay[]`, plus `weekOverrides` (per-week day
overrides), an edited `week` selector, and per-day `collapsed` flags. In edit
mode prefill from the existing program; in catalog mode the program to edit
arrives via navigation state (the canonical catalog copy).

1. **Header:** eyebrow = `Admin · Catalog` (catalog mode) / `Edit program` /
   `Build your own`; title "Edit Program" or "Create Program".
2. **Basics card:**
   - Program name (text).
   - Category (picker: Bodybuilding, Strength, HIIT, Powerlifting, Functional,
     Bodyweight) + Level (Beginner/Intermediate/Advanced), side by side.
   - Weeks / Days-per-week (numeric) + Coach (text), three-up.
   - **Accent color** swatch picker (row of round color buttons from a preset
     `ACCENTS` list; selected has a white ring). This accent themes the program
     everywhere.
   - Summary (short, one line) + Description (multiline).
   - **Collaborative** toggle (Yes/No) — hidden in catalog mode; only the owner
     can change it. Caption explains: collaborative = anyone who added it can
     edit (edits apply to all); non-collab = only you edit (still applies to
     all). 
3. **Training Days section** (`Training Days · {days.count}`):
   - **Week selector** (only if `durationWeeks > 1`): −/＋ chevrons + "Week {w} /
     {total}", with a note (Week 1 = base plan applies to un-edited weeks; Week
     N>1 = changes apply from week N onward). A "Copy Week {w} to all weeks"
     button (confirm inline) overwrites every week with the current week's plan.
     Editing a week other than 1 writes a per-week override; day add/remove is
     disabled when `week > 1` (structure is fixed past week 1).
   - **Day cards** (resolved for the selected week): a collapse chevron, Day name
     + Focus inputs (two-up), and a remove-day trash (disabled when only one day
     or `week > 1`). When expanded, the exercise builder:
     - Render exercises via `supersetGroups`. **Standalone exercise row:** a
       name input with **library type-ahead** (`ExerciseNameInput`; free text =
       custom), up/down reorder buttons, a cue button (§5), a remove trash, a
       caption `{primaryMuscle} · {equipment}` or "Custom exercise", a three-up
       Sets (num) / Reps (text) / Rest (num) field row, the cue subheader, and a
       dashed **"Superset with next"** button (when not the last exercise) that
       links this exercise with the one below into a group.
     - **Superset group block:** an accent-bordered container holding its member
       rows (each tagged A1/A2/…) with the same fields, shared rest on the last
       member, and an **"Unlink"** action to break the group back into
       standalone exercises. (`linkWithNext` assigns a shared `groupId` +
       normalizes set counts; `unlinkGroup` clears `groupId`.)
     - An **"Add exercise"** button per day.
   - An **"Add day"** button under the list.
4. **Validation + Save** (sticky/footer primary): require a name, ≥1 day, ≥1
   named exercise per day (also validate week overrides). Build the `Program`
   (id = existing or `custom-{uid}`, `version = now`, owner = current user,
   `weekOverrides` when present).
   - **Normal:** persist locally (`addProgram`/`updateProgram`) then publish via
     `apiUpsertProgram` (adopt the server's canonical copy); navigate to the
     program detail (edit) or Programs list (new).
   - **Catalog mode:** fetch the catalog, upsert this program into its
     `programs`, `PUT /api/admin/catalog` (admin token), update the in-memory
     built-ins, and return to `/admin/catalog`.
5. **Error line** shows the first validation/save problem.

> CLI prompt — "Build the Program editor per docs/ios-swiftui-screens.md §9.
> State mirrors the Program model plus weekOverrides, a week selector, and
> per-day collapse flags; prefill in edit mode, and support a catalogMode that
> edits the shared built-in catalog (admin) from a program passed via nav state.
> Header eyebrow/title per mode. Basics card: name; category + level pickers;
> weeks/days-per-week/coach; an accent swatch picker; summary + description; and
> a collaborative Yes/No toggle (hidden in catalog mode, owner-only) with the
> explanatory caption. Training Days section: a week selector (>1 week) with the
> base-vs-from-week note and a 'Copy week to all weeks' confirm (day add/remove
> disabled past week 1); day cards with collapse, name/focus inputs, remove-day;
> and the exercise builder using `supersetGroups` — standalone rows (library
> type-ahead name input, reorder, cue (§5), remove, Sets/Reps/Rest fields, cue
> subheader, 'Superset with next') and superset group blocks (A1/A2 tagged
> members, shared rest, Unlink), plus Add-exercise and Add-day. Validate name/≥1
> day/named exercises (incl. overrides), build the Program (id, version=now,
> owner, weekOverrides), then in normal mode addProgram/updateProgram +
> apiUpsertProgram and navigate to detail/list, or in catalog mode upsert into
> the catalog via PUT /api/admin/catalog and return to /admin/catalog. Use the
> shared Theme. Build and run in the iOS Simulator and show me."

---

## 10. Standalone Timer (Timer tab) — `src/pages/Timer.tsx`

A self-contained tool with three modes selected by a top segmented control. The
selected mode persists (`timerMode` in the store).

1. **Header:** title "Timer" (Oswald). **Mode segmented control:** Timer /
   Stopwatch / Interval.

2. **Timer (Countdown):** a big circular **ProgressRing** (value = remaining /
   total) with the time in the center (mm:ss). A 3-2-1 "Get ready!" pre-count
   before it starts; "Time's up!" when done. An input accepting `mm:ss` or raw
   seconds (Enter starts) and a Start/Reset/Cancel button. An **Alert sound**
   picker (`SOUND_OPTIONS`, e.g. Bell) with a preview play button — selecting or
   previewing plays the sound. A **Recent timers** list (saved presets): tap to
   load, trash to remove.

3. **Stopwatch:** a large mm:ss.cc display (centiseconds), Start/Pause + Reset
   (and lap if present). Counts up.

4. **Interval:** an interval/HIIT timer with three formats (segmented):
   - **EMOM** — every `emomInterval`s for `emomRounds` rounds, `emomSets` sets
     with `emomSetRest` between sets.
   - **TABATA** — `tabataWork`s work / `tabataRest`s rest × `tabataRounds`,
     `tabataSets` sets with `tabataSetRest`.
   - **AMRAP** — a single `amrapCap`-minute (cap) work block.
   Numeric setting fields per format (with min/max validation). A live runner
   showing the current **phase** (work / rest / set-rest), round/set counters,
   the phase clock, total session time, and a final-3-seconds tick beep before
   each phase change; play the alert sound at phase transitions. Start/Pause/
   Reset controls.

5. **Sound / background:** route all timer sounds through the shared audio
   layer; configure `AVAudioSession` for background playback (as in §4) so the
   timer's end/phase sounds fire when the app is backgrounded or the screen is
   locked, with a local-notification fallback for the countdown finishing.

> CLI prompt — "Build the standalone Timer (Timer tab) per
> docs/ios-swiftui-screens.md §10. A 'Timer' title and a Timer/Stopwatch/
> Interval segmented control whose selection persists (timerMode). Timer mode: a
> circular ProgressRing (remaining/total) with centered mm:ss, a 3-2-1 'Get
> ready!' pre-count and 'Time's up!' end state, an input accepting mm:ss or
> seconds (Enter starts), Start/Reset/Cancel, an alert-sound picker with preview,
> and a Recent-timers list (load/remove). Stopwatch: mm:ss.cc count-up with
> Start/Pause/Reset. Interval: EMOM/TABATA/AMRAP formats with their numeric
> settings and validation, and a runner showing phase (work/rest/set-rest),
> round/set counters, phase + total clocks, a final-3s tick beep, and the alert
> sound at phase changes. Configure AVAudioSession for background playback (as in
> §4) so timer sounds fire when backgrounded/locked, with a local-notification
> fallback. Use the shared Theme. Build and run in the iOS Simulator and show me."

---

# Batch 4 — Progress hub, history screens, Max tracker

The Progress tab (Profile) and the screens it links to: full workout/body-weight
history, completed-program archive, and the personal-records Max tracker.

---

## 11. Progress / Profile (Profile tab) — `src/pages/Progress.tsx`

The hub for stats, body weight, trackers, and recent history.

1. **Title:** "Progress" (Oswald).
2. **Stat row** (3 cards): Workouts = `logs.count`; Day streak =
   `computeStreak(logs)`; Volume = `(totalVolume(logs)/1000)` shown as `{x.x}k`
   with label `Volume ({unit})`.
3. **Trackers** (two nav rows → list/detail): "Nutrition" (→ § Nutrition, later
   batch) and "Max Tracker" (→ §14), each a card with an accent icon tile.
4. **Body Weight card:**
   - Header "Body Weight" + `{unit}`.
   - **Trend chart:** a line+area sparkline of all entries (x = index, y =
     weight, normalized to min/max). Show the latest weight big and the delta
     "since start" (green if down, accent if up). If <2 entries, show a dashed
     empty box ("Log your weight to start a trend line." / "Log one more entry
     to see your trend.").
   - **Add row:** decimal weight input (placeholder `Today's weight ({unit})`,
     Enter submits) + a "Log" button → append a `BodyWeightEntry` (id, date =
     today, weight, createdAt = now) via `addBodyWeight`.
   - **Recent list:** last 5 entries (newest first); each row shows date/time +
     `{weight} {unit}` + a delete trash. A "Show More" link → §12 body-weight
     history when >5 entries.
5. **Workout History section:** header + "Show More" (→ §12) when >5 logs. List
   the 5 most recent logs as **WorkoutHistoryItem** cards: day name, `{program}
   · {date}`, then a meta row of duration, set count, and `↗ {totalVolume}
   {unit}` in accent; tapping opens that program; a delete trash removes the log.
   Empty state: "No workouts logged yet. Finish a session to see it here."

> CLI prompt — "Build the Progress/Profile tab per docs/ios-swiftui-screens.md
> §11. Title 'Progress'; a 3-stat row (Workouts = logs count, Day streak =
> computeStreak, Volume = totalVolume/1000 as '{x.x}k Volume ({unit})'); two
> tracker nav rows (Nutrition, Max Tracker); a Body Weight card with an
> all-entries line+area trend sparkline (latest value big + delta since start,
> green down / accent up, dashed empty state under 2 entries), a decimal
> add-weight input + Log button that appends a BodyWeightEntry via addBodyWeight,
> and a last-5 recent list (date/time + weight + delete) with a 'Show More' link
> to body-weight history when >5; and a Workout History section showing the 5
> most recent logs as cards (day name, program · date, duration / set count / ↗
> volume in accent, tap → program, delete trash) with a 'Show More' link when >5
> and the empty state. Use the shared Theme. Build and run in the iOS Simulator
> and show me."

---

## 12. Workout history + Body-weight history — `src/pages/ProgressHistory.tsx`

Two simple "show more" list screens, each with a Back link to Progress.

- **Workout history** (`/progress/history`): title "Workout History", subtitle
  "Your 20 most recent finished workouts.", a list of the 20 most recent logs
  reusing the **WorkoutHistoryItem** card from §11. Empty state with a dumbbell
  icon: "No workouts logged yet."
- **Body-weight history** (`/progress/weight`): title "Body Weight", subtitle
  "Every logged entry, newest first.", the full list reusing the **body-weight
  row** from §11 (date/time + weight + delete). Empty state with a scale icon:
  "No weight entries yet."

> CLI prompt — "Build the two history screens per docs/ios-swiftui-screens.md
> §12. Workout History (/progress/history): Back link to Progress, title +
> 'Your 20 most recent finished workouts.' subtitle, and a list of the 20 most
> recent logs reusing the WorkoutHistoryItem card from §11 (with empty state).
> Body Weight history (/progress/weight): Back link, title + 'Every logged entry,
> newest first.' subtitle, and the full list of entries reusing the §11
> body-weight row (with empty state). Use the shared Theme. Build and run in the
> iOS Simulator and show me."

---

## 13. Program history — `src/pages/ProgramHistory.tsx`

An archive of fully **completed** programs (`completedPrograms`), each a
snapshot of the program plus every workout logged during that run. Reached from
Programs (and/or Progress).

1. **List view:** Back link to Programs, title "Program History" + subtitle
   "Completed programs are saved here." Entries sorted newest-first by
   `completedAt`; each row card shows the program name, completion date, a count
   of logged workouts, and a chevron; a delete (two-tap confirm) removes it via
   `removeCompletedProgram`. Empty state (dumbbell icon): "No completed programs
   yet." + "Finish every week of a program and it'll be archived here."
2. **Detail view** (selecting an entry): Back to the list, the program name +
   completed date, then its archived workout logs grouped/ordered by day —
   showing the weights × reps actually performed on each day of that run. Theme
   the screen with the program's `accent`.

> CLI prompt — "Build Program History per docs/ios-swiftui-screens.md §13. List
> view: Back to Programs, title + 'Completed programs are saved here.' subtitle,
> the completedPrograms sorted newest-first by completedAt as cards (name,
> completion date, logged-workout count, chevron, two-tap delete via
> removeCompletedProgram), and the empty state. Selecting an entry opens a detail
> view (Back to list) showing the program name + completed date and its archived
> workout logs by day with the weights×reps performed, themed with the program
> accent. Use the shared Theme. Build and run in the iOS Simulator and show me."

---

## 14. Max tracker + detail — `src/pages/MaxTracker.tsx`, `MaxTrackerDetail.tsx`

Personal-records tracker: one card per lift, each holding dated max records.

**List (`/max`):** Back, eyebrow "Personal records" + title "Max Tracker", and a
"New" button. New opens an inline form card (Exercise name; Max weight ({unit})
+ Reps, two-up; Save/Cancel) with required-field validation (name non-empty,
weight ≥0, reps >0); Save calls `addMaxRecord(name, record)` where record =
{id, date today, weight, reps} (creating the lift card if new). A search field
(when any exist) filters by name. List each lift as a card → `/max/{id}`, showing
the name and its latest record `{weight} {unit} × {reps}`. Empty state
(dumbbell): "No lifts tracked yet. Tap 'New' to log your first max."

**Detail (`/max/:id`):** Back; the lift name + "Best: {max weight} {unit}". A
**Trend** card charting each record's weight over time (themed accent; empty /
one-more labels like the body-weight chart). A "Log a max" card (Weight ({unit})
+ Reps, two-up, validated) → `addMaxRecord`. A "History" list of all records
(newest first: date + `{weight} {unit} × {reps}` + two-tap delete via
`deleteMaxRecord`). A red-bordered "Delete tracker" card (two-tap confirm) →
`deleteMaxTracker` then back to `/max`.

> CLI prompt — "Build the Max tracker per docs/ios-swiftui-screens.md §14. List
> (/max): Back, 'Personal records' eyebrow + 'Max Tracker' title, a New button
> opening an inline form (Exercise name; Max weight ({unit}) + Reps; Save/Cancel)
> with validation (name, weight≥0, reps>0) that calls addMaxRecord(name, {id,
> date, weight, reps}); a name search when any exist; a card per lift → /max/{id}
> showing name + latest '{weight} {unit} × {reps}'; and the empty state. Detail
> (/max/:id): Back, lift name + 'Best: {max} {unit}', a Trend chart of record
> weights over time (accent, empty/one-more labels), a 'Log a max' card
> (Weight + Reps, validated) → addMaxRecord, a History list (newest first, date +
> weight×reps + two-tap delete via deleteMaxRecord), and a red 'Delete tracker'
> card (two-tap confirm) → deleteMaxTracker then back to /max. Use the shared
> Theme. Build and run in the iOS Simulator and show me."

---

# Batch 5 — People, Settings, Nutrition

The social tab, the settings hub, and the nutrition tracker. All reuse §0.

---

## 15. People / Search + following (Search tab) — `src/pages/People.tsx`

Find other athletes, follow them, and add their shared programs/exercises. All
calls require auth (`getToken()`); the screen needs sign-in to work.

1. **Header:** eyebrow "Train together" + title "People", subtitle "Find other
   athletes by name, follow them, and add their programs."
2. **Search card:** a search field (leading magnifier). **Debounce** input ~350ms
   then call `apiSearchUsers(token, q)` → `[DiscoverUser]` (each has id, name,
   `following` bool, shared program/exercise counts). Show "Searching…" while in
   flight, an empty "no results" line when a completed search returns none, else
   a list of **SearchResultCard**s: name, a Follow/Following toggle button
   (`apiFollow`/`apiUnfollow`, optimistic), and — when the user has shared
   content — an expandable **SharedContent** section (see §15a).
3. **Following section:** a Users icon + "Following ({n})". Sorted (favorites
   first). Each is a **FollowingCard**: name, an Unfollow button, a favorite star
   (`favoriteUserIds`, max 5 — disabled when full & not already a favorite), and
   the same expandable SharedContent. Empty state: "You're not following anyone
   yet. Search above to find athletes and follow them."

### 15a. SharedContent (a user's shared programs/exercises)
Lazy-loads on expand via `apiUserPrograms(token, userId)` /
`apiUserExercises(token, userId)`. Lists each shared **program** with an **Add**
button that opens a **Follow vs Duplicate** choice:
- **Follow** — `apiAddProgram(token, p.id)`: keeps it linked to the creator
  (stays read-only; their future edits sync in).
- **Duplicate** — a standalone owned copy (fresh id) you can edit/share.
Either way, backfill referenced custom-exercise names/imports so nothing shows a
raw `custom-…` id. An **Add** on each shared **exercise** imports it via
`addCustomExercise`. Added items show a **Remove** that undoes the add
(`deleteProgram` / removes the custom exercise). Track added ids so the buttons
reflect state.

> CLI prompt — "Build the People/Search tab per docs/ios-swiftui-screens.md §15
> (auth required). Header eyebrow 'Train together' + 'People' title + subtitle. A
> search field that debounces ~350ms and calls apiSearchUsers → DiscoverUser
> list, with a 'Searching…' state, a no-results line, and SearchResultCards
> (name, Follow/Following toggle via apiFollow/apiUnfollow optimistic, and an
> expandable shared-content section when the user has shares). A Following
> section (Users icon + count, favorites-first sort) of FollowingCards (name,
> Unfollow, favorite star with favoriteUserIds max 5, expandable shared content)
> with its empty state. SharedContent (§15a) lazy-loads via apiUserPrograms /
> apiUserExercises and lets you Add each program with a Follow (apiAddProgram,
> stays linked/read-only) vs Duplicate (standalone owned copy) choice —
> backfilling referenced custom-exercise names — and Add each exercise via
> addCustomExercise, each with a Remove that undoes it; track added ids for
> button state. Use the shared Theme. Build and run in the iOS Simulator and show
> me."

---

## 16. Settings — `src/pages/Settings.tsx`

A stack of cards. Subtitle line at the very bottom: "NextRep · Train with
intent."

1. **Title** "Settings".
2. **Display name** card: a text field bound to `name` (`setName`).
3. **Admin card** (only when `account.is_admin`): two nav rows — "Users" (→
   `/admin/users`, "Admin · view registered users") and "Catalog" (→
   `/admin/catalog`, "Admin · edit built-in programs & exercises").
4. **Appearance** card: **Theme color** swatches (`THEME_COLORS`, selected has a
   ring + check), **Theme** mode segmented (Light / Dark / System), and **Weight
   unit** segmented (kg / lb) bound to `unit` (`setUnit`).
5. **Active Program** card: if set, show its name with "View" + "Change" links;
   else a "Browse Programs" button.
6. **Account** card (when signed in): name + email; a **Change Password** control
   (current + new password fields → API); and a **Log out** button (two-tap
   confirm → `logout` + go to `/login`).
7. **Install app** card: a PWA install prompt (native prompt when available, else
   an "Add to Home Screen" instructions sheet) — on iOS native this can be
   omitted/replaced with nothing since it's already an installed app.
8. **Data Reset** card (red border): explains it clears active program, history,
   and body-weight; a two-tap "Reset All Data" → `resetAll`.
9. **Legal** card: nav rows to Privacy Policy, Terms of Service, and Health &
   Fitness Disclaimer (→ §Legal, later batch).

> CLI prompt — "Build Settings per docs/ios-swiftui-screens.md §16. A stack of
> cards: title 'Settings'; a Display name field bound to name/setName; an
> admin-only card (account.is_admin) with Users → /admin/users and Catalog →
> /admin/catalog rows; an Appearance card with THEME_COLORS swatches (ring +
> check on selected), a Light/Dark/System theme-mode segmented control, and a
> kg/lb weight-unit segmented control bound to unit/setUnit; an Active Program
> card (name + View/Change, or Browse Programs); an Account card (name + email, a
> Change Password control hitting the API, and a two-tap Log out → logout +
> /login); a Data Reset card (red, two-tap 'Reset All Data' → resetAll, with the
> warning copy); and a Legal card linking Privacy / Terms / Disclaimer. Footer
> 'NextRep · Train with intent.' Omit the PWA install card on native iOS. Use the
> shared Theme. Build and run in the iOS Simulator and show me."

---

## 17. Nutrition — `src/pages/Nutrition.tsx`

A per-day food/macro/hydration log. State: `nutritionLog` (entries keyed by
`date`), `nutritionGoals`, and a selected `date` (defaults today). The current
entry = the log row for `date` or a zeroed `{calories, protein, carbs, fat,
water, photos}`.

1. **Header:** eyebrow "Daily fuel" + title "Nutrition", subtitle "Log your daily
   calories, macros, and hydration."
2. **Date picker:** a date field (max = today) selecting which day to view/edit; a
   collapsible **History** list (each past day → date + `{cal} kcal ·
   {p}/{c}/{f}g · {water} 💧`, tap to jump to that date, current day ringed).
3. **Calories card:** a circular **Ring** (current/goal) + an **AddField** ("Add
   calories": a number input that *adds* its value to the running total on
   submit). All adds clamp at ≥0.
4. **Macros card:** three **MacroRow**s (Protein, Carbs, Fat) each showing
   value/goal + an add input (`add(field, v)`).
5. **Water card:** a row of glass buttons (count = max(goal, current)); tapping
   glass i sets water to i+1 (or i if already exactly that) — a fill-to-here
   toggle.
6. **Goals editor:** an expandable card; a draft of calories/protein/carbs/fat/
   water number fields + a "Save Goals" button (→ `setNutritionGoals`, shows
   "Saved" briefly).
7. **Day photos:** up to 3 progress photos per day (compressed to small JPEGs),
   stored on the entry.

All edits go through `setNutritionEntry({...entry, [field], date})` so they're
bound to the selected day.

> CLI prompt — "Build Nutrition per docs/ios-swiftui-screens.md §17. State:
> nutritionLog (entries by date), nutritionGoals, a selected date defaulting to
> today; the current entry = that day's row or a zeroed one. Header eyebrow
> 'Daily fuel' + 'Nutrition' + subtitle. A date picker (max today) plus a
> collapsible History list (date + '{cal} kcal · {p}/{c}/{f}g · {water} 💧', tap
> to jump, current day ringed). A Calories card with a circular Ring
> (current/goal) and an AddField that adds its value to the total. A Macros card
> with Protein/Carbs/Fat rows (value/goal + add input). A Water card of glass
> buttons (count = max(goal, current)) where tapping glass i sets water to i+1 or
> i (fill-to-here toggle). An expandable Goals editor (calories/protein/carbs/fat/
> water draft fields + 'Save Goals' → setNutritionGoals, brief 'Saved'). And up
> to 3 compressed day photos. All edits clamp ≥0 and go through setNutritionEntry
> bound to the selected date. Use the shared Theme. Build and run in the iOS
> Simulator and show me."

---

# Batch 6 — Auth, Legal, Admin (final batch)

The unauthenticated entry screens, the static legal docs, and the two admin
screens. After this batch, every web screen has a SwiftUI spec.

---

## 18. Auth — login / signup — `src/pages/Auth.tsx`

A single screen with a `mode` of `login` or `signup`. If already authenticated
(`token` present) redirect to the Dashboard.

1. **Brand block:** a centered accent dumbbell tile, the wordmark "Next**Rep**"
   (accent on "Rep", wide tracking), and a subtitle ("Create your account to
   start training." for signup / "Welcome back. Log in to continue." for login).
2. **Form card:**
   - **Name** field (signup only).
   - **Email** field (keyboard = email).
   - **Password** field (secure, with a show/hide toggle = the `PasswordField`
     component) + live **PasswordHints** (rule checklist). On login, a "Forgot
     password?" link (→ §20) right-aligned beneath.
   - An error banner when the call fails.
   - Submit button: "Create account" / "Log in" (disabled + "Please wait…" while
     busy). On success (`signUp(name,email,password)` / `login(email,password)`)
     navigate to `/` (replace).
3. **Footer link** toggling to the other mode ("Already have an account? Log in"
   / "New here? Create an account").

> CLI prompt — "Build the Auth screen per docs/ios-swiftui-screens.md §18 with a
> login/signup mode (redirect to Dashboard if already authenticated). A centered
> brand block (accent dumbbell tile, 'NextRep' wordmark with accent 'Rep',
> mode-dependent subtitle); a form card with a Name field (signup only), an email
> field, a secure password field with show/hide and live password-rule hints, a
> right-aligned 'Forgot password?' link on login, an error banner, and a submit
> button ('Create account'/'Log in', disabled + 'Please wait…' while busy) that
> calls signUp/login and navigates to / on success; and a footer link toggling
> between login and signup. Use the shared Theme. Build and run in the iOS
> Simulator and show me."

---

## 19. Reset password — `src/pages/ResetPassword.tsx`

Reached from the emailed link (`/reset-password?token=…`); reads the `token`
query param. Redirect to Dashboard if already authenticated.

Same brand block ("Choose a new password."). Form: a new **Password** field
(secure + hints) and a **Confirm** field. Validate length ≥6 and that the two
match, then call `apiResetPassword(token, password)`. On success show a success
card (check icon + "Your password has been reset. You can now log in…") with a
"Back to log in" button; on failure show the error.

## 20. Forgot password — `src/pages/ForgotPassword.tsx`

Same brand block ("Reset your password."). A single **Email** field + "Send reset
link" button → `apiForgotPassword(email)`. On success show a confirmation card
(mail icon + "If an account exists for {email}, we've sent a link… expires in 1
hour.") with "Back to log in". A footer "Remembered it? Log in" link.

> CLI prompt — "Build the password-reset flow per docs/ios-swiftui-screens.md
> §19–§20 (both redirect to Dashboard if authenticated, both use the NextRep
> brand block). Forgot password: an email field + 'Send reset link' →
> apiForgotPassword, then a confirmation card ('If an account exists for {email}
> we've sent a link… expires in 1 hour') with 'Back to log in', and a 'Remembered
> it? Log in' footer. Reset password: read the token query param, a new-password
> field (secure + hints) + a confirm field, validate length ≥6 and match, call
> apiResetPassword(token, password), then a success card (check + message + 'Back
> to log in') or an error. Use the shared Theme. Build and run in the iOS
> Simulator and show me."

---

## 21. Legal — `src/pages/Legal.tsx`

A static document screen with a `doc` of `privacy` / `terms` / `disclaimer`
(reached from the Settings legal links). Back button; an `<h1>` title from a
`TITLES` map; a "Last updated: {date}" line; and a card rendering the selected
document's prose (headings, paragraphs, bullet lists, bold). Port the three
documents' text verbatim from the web app (Privacy Policy, Terms of Service,
Health & Fitness Disclaimer), keeping the app name and contact email.

> CLI prompt — "Build the Legal screen per docs/ios-swiftui-screens.md §21: a
> doc parameter (privacy/terms/disclaimer), a Back button, an h1 title from a
> TITLES map, a 'Last updated: {date}' line, and a card rendering the selected
> document's prose (headings/paragraphs/bullets/bold). Port the three documents'
> text verbatim from src/pages/Legal.tsx (Privacy Policy, Terms of Service,
> Health & Fitness Disclaimer), keeping the app name and contact email. Use the
> shared Theme. Build and run in the iOS Simulator and show me."

---

## 22. Admin · Users — `src/pages/AdminUsers.tsx`

Admin-only (redirect non-admins to `/`). Back button; eyebrow "🛡 Admin" + title
"Users" + a "{n} registered users" count. Loads `apiAdminUsers(token)` →
`[AdminUser]`. Each is a **UserCard**: name, "Joined {date}", email, "Last
active: {datetime|Never}", and a collapsible **Reset password** control (a secure
field, ≥6 chars, → `apiAdminResetPassword(token, userId, password)`, with a
success/error message). Show a loading line and an error card as needed.

> CLI prompt — "Build Admin · Users per docs/ios-swiftui-screens.md §22 (admin
> only — redirect non-admins to /). Back button, '🛡 Admin' eyebrow + 'Users'
> title + '{n} registered users' count; load apiAdminUsers → AdminUser list and
> render a card per user (name, Joined {date}, email, Last active {datetime or
> Never}) with a collapsible Reset-password control (secure field, ≥6 chars →
> apiAdminResetPassword, success/error message); plus loading and error states.
> Use the shared Theme. Build and run in the iOS Simulator and show me."

---

## 23. Admin · Catalog — `src/pages/AdminCatalog.tsx`

Admin-only (redirect non-admins). Edits the **shared built-in catalog** that
every client reads from `GET /api/catalog`. Back button; eyebrow "🛡 Admin" +
title "Catalog" + "Edit the built-in programs and exercises everyone sees.
Changes go live immediately." Loads `apiGetCatalog()` → `{programs, exercises}`.

1. **Programs section** ("Programs · {n}"): an **Add** button → the §9 Program
   editor in **catalog mode** (new). Each program row → edit in catalog mode
   (passing the program), plus a delete (two-tap confirm).
2. **Exercises section** ("Exercises · {n}"): an inline **ExerciseForm**
   (name; primary-muscle, equipment, difficulty pickers; secondary muscles
   comma list; instructions + tips, one per line) for new/edit, and a row per
   exercise with edit + delete (two-tap confirm). Ids are slugified from the
   name.
3. **Persist:** every add/edit/delete writes the whole catalog via
   `apiAdminPutCatalog(token, {programs, exercises})`, then updates the in-memory
   built-ins (`setBuiltInPrograms`/`setBuiltInExercises`) so the change is live
   immediately. (See §9's catalog-mode save for the program path.)

> CLI prompt — "Build Admin · Catalog per docs/ios-swiftui-screens.md §23 (admin
> only — redirect non-admins). Back button, '🛡 Admin' eyebrow + 'Catalog' title
> + the 'everyone sees / live immediately' subtitle; load apiGetCatalog →
> {programs, exercises}. A Programs section ('Programs · {n}') with an Add button
> opening the §9 Program editor in catalog mode (new) and rows that open it in
> catalog mode for editing (pass the program), each with a two-tap delete. An
> Exercises section ('Exercises · {n}') with an inline ExerciseForm (name;
> primary-muscle / equipment / difficulty pickers; secondary muscles as a comma
> list; instructions + tips one-per-line) for new/edit and rows with edit +
> two-tap delete (ids slugified from the name). Every change persists the whole
> catalog via apiAdminPutCatalog then updates the in-memory built-ins
> (setBuiltInPrograms/setBuiltInExercises) so it's live immediately. Use the
> shared Theme. Build and run in the iOS Simulator and show me."

---

## All screens specified

Batches 1–6 now cover every screen in the web app:
Dashboard, Programs list, Program detail, Active Workout + rest timer, cue/notes
(§1–5); Day review/edit, Exercises library, Exercise detail (§6–8); Program
editor, standalone Timer (§9–10); Progress, history screens, Program history,
Max tracker (§11–14); People, Settings, Nutrition (§15–17); Auth, password
reset, Legal, Admin Users + Catalog (§18–23). Plus §0 foundations (theme, nav,
shared helpers) and the API/data-model reference in
`docs/ios-swiftui-handoff.md`.
