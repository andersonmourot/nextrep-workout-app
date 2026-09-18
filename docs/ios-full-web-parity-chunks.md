# NextRep iOS full web parity chunks

This document tracks the remaining work to bring the native SwiftUI app in
`ios/NextRepStarter` to full parity with the React web app in `src/`.

The SwiftUI starter already covers the core native foundation: auth, sync,
program listing/detail/editing, exercise library/editing, active workout,
finish summary, rest notifications, profile history, nutrition/max tracking,
people search, settings, and admin basics. The chunks below focus on closing
behavioral, visual, and edge-case gaps.

## Current status

As of the latest native parity pass, the major feature chunks below have been
implemented in `ios/NextRepStarter`: shared domain/store behavior, app shell,
theme mode/accent behavior, Dashboard, Programs list/detail/history/editor,
Active Workout, Day Review, Exercise Library/Detail, Timer/native sound
selection, People/social sharing, Profile/Progress, Nutrition, Max Tracker,
auth recovery/password UX, Settings/legal, Admin Users, Admin Catalog program
and exercise management, and data-integrity cleanup. The remaining work is
primarily final regression, device-specific QA, and App Store/TestFlight polish.

## Chunk 0: shared domain engine and store parity

**Web references**
- `src/lib/utils.ts`
- `src/store.ts`
- `src/types.ts`

**Swift status**
- Models exist in `Models/AppModels.swift`.
- `Store/AppStore.swift` has first-pass mutations only.

**Scope**
- Port `programRun`, `resolveProgramDay`, `withDayOverride`,
  `programLogSlots`, `logSlotIndex`, `previousWeekWeights`,
  `supersetGroups`, `computeStreak`, `workoutsThisWeek`, and volume/date
  helpers.
- Add missing store behavior: `addLog`, `deleteLog`, program reset anchors,
  completed program archival, favorite programs/users, hide/trash/restore/purge,
  exercise overrides, saved timers, interval settings persistence, nutrition
  entry update semantics, max record update/delete, shared batch refresh.

**Acceptance criteria**
- Swift progress/day/workout behavior matches the web app for week/day slots.
- Finishing the last workout of a full program archives a `CompletedProgram`.
- Followed shared programs/exercises refresh from batch endpoints after login.

## Chunk 1: app shell and live workout UX

**Web references**
- `src/components/Layout.tsx`
- `src/components/BottomNav.tsx`
- `src/components/Logo.tsx`
- `src/App.tsx`

**Swift status**
- `RootView.swift` has a basic `TabView`.
- Workout is pushed through navigation links.

**Scope**
- Add global app header/logo behavior where appropriate.
- Add sticky Resume Workout banner across tabs when `activeWorkout` exists.
- Present Active Workout as a full-screen flow that hides tab chrome.
- Close workout without ending the session.

**Acceptance criteria**
- A live workout can be resumed from any tab.
- Workout close keeps all entered set data.
- Tab bar and workout chrome match the web/native handoff behavior.

## Chunk 2: design system and theme parity

**Web references**
- `src/lib/theme.ts`
- `src/index.css`
- `tailwind.config.js`
- `docs/ios-swiftui-screens.md`

**Swift status**
- `Theme.swift` has dark tokens and dynamic accent.
- Fonts are system fonts.

**Scope**
- Bundle/use Oswald and Inter.
- Add reusable text styles for heading, eyebrow, body, caption, chips.
- Implement light/dark/system appearance from `themeMode`.
- Ensure generic accent usage follows selected app theme, while program cards
  preserve program-specific accent colors.

**Acceptance criteria**
- Color, typography, radii, glow, and card treatments match the web visual
  language.
- Theme color changes apply everywhere the web app's CSS variables apply.

## Chunk 3: Dashboard full parity

**Web reference**
- `src/pages/Dashboard.tsx`

**Swift status**
- `DashboardView.swift` is partial.

**Scope**
- Use `programRun` and `programAnchors` for current week/day.
- Add hero states: active next day, program complete, no active program.
- Add Week/Day chip and exercise preview chips.
- Add 3-stat row with streak, weekly progress ring, and total workouts.
- Start/Resume should pass correct week/day to `startWorkout`.

**Acceptance criteria**
- Home matches web dashboard behavior and no longer uses naive log-count modulo.

## Chunk 4: Programs list parity

**Web reference**
- `src/pages/Programs.tsx`

**Swift status**
- `ProgramsListView.swift` has basic search/list and toolbar actions.

**Scope**
- Add category filter chips.
- Restore active/favorites-first ordering and favorite toggle with max cap.
- Add manage mode for hide/delete.
- Add hidden and trash views with restore/purge.
- Add Program History entry point.

**Acceptance criteria**
- Program list behavior matches web, including manage/trash flows and ordering.

## Chunk 5: Program detail parity

**Web reference**
- `src/pages/ProgramDetail.tsx`

**Swift status**
- `ProgramDetailView.swift` has hero, set active, day cards, management actions.

**Scope**
- Add week pager and `resolveProgramDay`.
- Add favorite star.
- Add up-next highlight and per-slot Done checks.
- Add logged set summaries in exercise rows.
- Add complete/reset/archive panel.
- Confirm before switching active program when another workout is in progress.

**Acceptance criteria**
- Program detail is week-aware and progress-aware like the web app.

## Chunk 6: program progress, anchors, and archive logic

**Web reference**
- `src/store.ts`

**Swift status**
- Fields exist but full logic is missing.

**Scope**
- Correctly set `WorkoutLog.week`.
- Implement `programAnchors`.
- Implement complete-program archival into `completedPrograms`.
- Add remove archived program behavior.

**Acceptance criteria**
- Program reset and completion behave exactly like web across multiple runs.

## Chunk 7: Program History

**Web reference**
- `src/pages/ProgramHistory.tsx`

**Swift status**
- Missing UI.

**Scope**
- Add archive list.
- Add archive detail view showing snapshot program and logs.
- Add delete archive action.

**Acceptance criteria**
- Completed programs are browsable even after original program changes/deletes.

## Chunk 8: Active Workout full parity

**Web references**
- `src/pages/Workout.tsx`
- `src/components/ExerciseNotesButton.tsx`
- `src/components/ExerciseSubheader.tsx`
- `src/lib/sound.ts`

**Swift status**
- `ActiveWorkoutView.swift` supports set logging, previous hints, rest
  notifications, and first-pass superset rest behavior.

**Scope**
- Render supersets round-by-round instead of plain exercise cards.
- Add exercise notes/cue controls directly in workout.
- Switch set entry from +/- controls to numeric fields matching web.
- Add sticky top bar and floating bottom rest bar with +15s and Skip.
- Add bell sounds and `AVAudioSession` background playback.
- Reconcile active workout when the program changes.

**Acceptance criteria**
- Workout screen matches web behavior and provides native background rest alerts.

## Chunk 9: Day Review and per-day logging/editing

**Web reference**
- `src/pages/DayReview.tsx`

**Swift status**
- `DayDetailView.swift` is read-only plus Start.

**Scope**
- Add week/day slot-aware log editing.
- Prefill from existing log or planned template.
- Add per-week day editing for custom programs.
- Save logs with week/day binding.
- Prefill previous-week weights.

**Acceptance criteria**
- Users can review and edit any program day slot like web.

## Chunk 10: Program Editor full parity

**Web reference**
- `src/pages/ProgramEditor.tsx`

**Swift status**
- `ProgramEditorView.swift` has first-pass editor, collapsible days, reorder,
  duplicate, autocomplete, accent picker, collaborative toggle, manual group ids.

**Scope**
- Add week selector and `weekOverrides`.
- Add Copy Week to All Weeks.
- Add built-in superset link/unlink workflows if desired.
- Publish owned/shared programs on save.
- Add admin catalog mode.
- Add exercise cue button in editor rows.

**Acceptance criteria**
- Program creation/editing matches web, including week-specific plans.

## Chunk 11: Exercise library and management parity

**Web references**
- `src/pages/Exercises.tsx`
- `src/pages/ExercisesLibrary.tsx`
- `src/data/exercises.ts`

**Swift status**
- `ExerciseLibraryView.swift` and `ExerciseEditorView.swift` cover basic
  list/search/detail/create/edit/delete/share.

**Scope**
- Add fixed muscle filter chips and custom filter.
- Add manage mode.
- Hide built-in exercises.
- Trash/delete custom exercises with restore/purge.
- Add built-in exercise overrides.

**Acceptance criteria**
- Exercise library management matches the web app.

## Chunk 12: Exercise detail and media parity

**Web reference**
- `src/pages/ExerciseDetail.tsx`

**Swift status**
- Exercise detail has photos display, notes/cues, usage list, share/edit.

**Scope**
- Add photo picker/camera import and compression for up to two photos.
- Add delete/hide with confirmations.
- Surface notes/cues everywhere the exercise appears.

**Acceptance criteria**
- Exercise detail can create and preserve the same media-rich exercise records as
  web.

## Chunk 13: Standalone Timer full parity

**Web reference**
- `src/pages/Timer.tsx`

**Swift status**
- `IntervalTimerView.swift` supports TABATA, EMOM, AMRAP basics.

**Scope**
- Add timer, stopwatch, and interval mode switch.
- Persist `timerMode`, `savedTimers`, `timerSound`, `intervalSettings`,
  `intervalFormat`.
- Add recent timers/presets.
- Add interval sets and set-rest flows.
- Add sound previews and background completion alerts.

**Acceptance criteria**
- Timer tab matches the web timer modes and adds native background reliability.

## Chunk 14: People and social discovery full parity

**Web reference**
- `src/pages/People.tsx`

**Swift status**
- `PeopleSearchView.swift` has manual search, follow/unfollow, user detail,
  shared content add/remove.

**Scope**
- Add debounced search.
- Add Following section from `/api/following`.
- Add favorite users.
- Add expandable shared-content cards.
- Add Follow vs Duplicate choice for programs and custom-exercise backfill.
- Add shared batch refresh after login.

**Acceptance criteria**
- Social discovery and shared content behavior matches web.

## Chunk 15: Profile / Progress hub full parity

**Web reference**
- `src/pages/Progress.tsx`

**Swift status**
- `WorkoutHistoryView.swift` has stats, tracker links, body weight, recent
  workouts.

**Scope**
- Rename/layout to match Progress/Profile web view.
- Add volume formatting like web.
- Add body-weight delta since start.
- Add workout delete on history rows.
- Tune recent/history limits.

**Acceptance criteria**
- Profile progress hub matches web data and affordances.

## Chunk 16: Workout and body-weight history pages

**Web reference**
- `src/pages/ProgressHistory.tsx`

**Swift status**
- `AllWorkoutHistoryView` exists. Dedicated body-weight history page is missing.

**Scope**
- Add workout history limit/empty state behavior.
- Add dedicated body-weight history page with full list and delete actions.

**Acceptance criteria**
- `/progress/history` and `/progress/weight` web flows have Swift equivalents.

## Chunk 17: Nutrition full parity

**Web reference**
- `src/pages/Nutrition.tsx`

**Swift status**
- `NutritionTrackerView` has daily targets, daily logging, progress bars, recent
  history.

**Scope**
- Add date picker/day navigation.
- Add incremental Add fields.
- Add water glass UI.
- Add calorie ring.
- Add up to three nutrition photos per day.
- Ensure per-day updates match `setNutritionEntry` semantics.

**Acceptance criteria**
- Nutrition behavior and visuals match web.

## Chunk 18: Max Tracker full parity

**Web references**
- `src/pages/MaxTracker.tsx`
- `src/pages/MaxTrackerDetail.tsx`

**Swift status**
- `MaxTrackerView` has inline add/list/chart.

**Scope**
- Add list search.
- Add detail screen per tracker.
- Add per-record history and delete.
- Add best value header and trend chart labels.

**Acceptance criteria**
- Max Tracker list/detail matches web.

## Chunk 19: Auth recovery parity

**Web references**
- `src/pages/Auth.tsx`
- `src/pages/ForgotPassword.tsx`
- `src/pages/ResetPassword.tsx`
- `src/components/PasswordField.tsx`
- `src/components/PasswordHints.tsx`

**Swift status**
- `AuthView.swift` has login/signup only.

**Scope**
- Add forgot password and reset password API methods.
- Add forgot/reset SwiftUI screens.
- Add password show/hide and password hints.
- Add deep link or token-entry support for reset token.

**Acceptance criteria**
- Full auth recovery flow works natively.

## Chunk 20: Settings and legal parity

**Web references**
- `src/pages/Settings.tsx`
- `src/pages/Legal.tsx`

**Swift status**
- `SettingsView.swift` covers most settings. Legal text is abbreviated.

**Scope**
- Port legal text verbatim.
- Add System theme mode.
- Confirm all Settings controls mirror web UI and behavior.

**Acceptance criteria**
- Settings and legal screens are functionally equivalent to web.

## Chunk 21: Admin catalog full parity

**Web references**
- `src/pages/AdminUsers.tsx`
- `src/pages/AdminCatalog.tsx`

**Swift status**
- Native admin users exist; catalog is publish/stats only.

**Scope**
- Add catalog program/exercise lists.
- Add add/edit/delete built-in catalog programs/exercises.
- Add Program Editor catalog mode.
- Add Exercise form for built-in exercise editing.
- Publish whole catalog.

**Acceptance criteria**
- Admin Catalog matches web admin tools.

## Chunk 22: Cross-cutting notes and cues parity

**Web references**
- `src/components/ExerciseNotesButton.tsx`
- `src/components/ExerciseSubheader.tsx`

**Swift status**
- Exercise Detail supports notes/cues. Workout/day/editor do not yet have the
  full controls.

**Scope**
- Add reusable note/cue SwiftUI controls.
- Use them in Active Workout, Day Detail/Review, and Program Editor rows.
- Ensure notes/cues stay private and are never shared.

**Acceptance criteria**
- Notes/cues behave like web everywhere exercises appear.

## Chunk 23: Native audio and notification payoff

**Web references**
- `src/lib/sound.ts`

**Swift status**
- Local notification and vibration exist.

**Scope**
- Add `AVAudioSession` playback/mixWithOthers.
- Bundle timer sounds.
- Add sound picker and preview.
- Ensure workout rest and interval timer sounds work when backgrounded/locked.

**Acceptance criteria**
- Native app solves the web/PWA background audio limitation.

## Chunk 24: Data integrity and sync edge cases

**Web references**
- `src/store.ts`
- `src/api.ts`

**Swift status**
- Unknown JSON round-trip exists. Many side effects are partial.

**Scope**
- Port custom exercise placeholder relinking.
- Port trash TTL purge.
- Port shared version conflict rules.
- Ensure all `PUT /api/data` calls preserve unknown fields.
- Add robust offline/local cache behavior.

**Acceptance criteria**
- Native and web clients can be used interchangeably without losing data.

## Implementation priority

1. Shared domain engine and store parity.
2. Active Workout, Day Review, Program Detail, Program Progress.
3. Program list/manage/history/editor full parity.
4. Timer plus native audio.
5. Social, Nutrition, Max Tracker, history pages.
6. Auth recovery, Admin Catalog, Settings/legal polish, final design pass.

Keep using the existing backend API and whole-blob data model. Add migrations or
schema-breaking changes only if both web and native clients are updated together.
