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

## Remaining screens (later batches — will detail on request)
Day review / Day edit (`DayReview.tsx`), Exercises library + Exercise detail,
Program/Exercise editors, Progress/Profile + history + body-weight, People/
Search + following, Settings, Timer (standalone), Max tracker, Nutrition,
Auth/forgot/reset, Legal, Admin (Users + Catalog).
