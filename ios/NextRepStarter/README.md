# NextRepStarter iOS scaffold

This folder is the native SwiftUI rebuild of the existing NextRep/SMELLIS web
app.

It is intentionally source-only. Create a new **iOS App** target in Xcode
(`File > New > Project > iOS > App`, SwiftUI, Swift), then copy the files in
this folder into that target. The code targets iOS 17+ and uses SwiftUI,
Observation, URLSession, and Keychain Services.

## What this starter includes

- `NextRepApp.swift` app entry point.
- `Theme/Theme.swift` with dynamic accent colors, light/dark/system mode
  support, and shared card/button styles.
- `Models/AppModels.swift` with Swift `Codable` models mirroring the current
  web data shape from `src/types.ts` and `src/store.ts`.
- `Models/JSONValue.swift` to round-trip unknown keys in the `/api/data` blob.
- `Services/APIClient.swift` for the existing FastAPI backend.
- `Services/KeychainStore.swift` for JWT persistence.
- `Services/RestTimerNotifier.swift` for rest-complete local notifications.
- `Store/DomainHelpers.swift` for shared program progress, week/day slotting,
  streaks, previous-week weights, and superset grouping logic.
- `Store/AppStore.swift` for login/session restore, catalog loading, data
  loading, and manual sync.
- `Views/*` with auth/login/signup plus password recovery, Home dashboard,
  Programs tab with Exercise Library access, Program Detail + Day Detail
  navigation, Search tab people discovery/following/social sharing,
  Timer/Stopwatch/Interval modes with selectable completion sounds, and Active
  Workout screens for set logging, notes/cues, supersets, rest timing, and
  finish summaries.
- Profile includes workout history, body-weight tracking, dedicated Nutrition
  target/tracking with daily photos, Max Tracker list/detail views, and logged
  set details.
- `ProgramHistoryView.swift` shows completed program archives and their saved
  workout logs.
- `DayLogEditorView.swift` supports manual day logging/editing outside the live
  workout flow.
- `SettingsView.swift` is available from the Profile toolbar and includes
  account, appearance, unit, active-program, password, reset, logout, and legal
  options.
- `VisualComponents.swift` provides reusable native progress rings, line charts,
  and metric progress bars used across Dashboard, Profile, Nutrition, Max
  Tracker, Program Detail, and Active Workout.
- `ProgramEditorView.swift` supports custom and admin catalog program/day/
  exercise creation and editing, including week-specific overrides, copy-week
  behavior, duplicate day/exercise controls, and superset group helpers.
- `ExerciseEditorView.swift` supports custom exercise creation/editing,
  built-in exercise overrides, restore-default behavior, and up to two
  compressed reference photos.
- Exercise detail supports reference photos when present, private notes/cues,
  built-in override editing, custom exercise share controls, and visible
  programs where an exercise appears.
- `WorkoutSummaryView.swift` shows the just-finished workout before returning to
  the previous screen.
- Custom Program and Exercise detail screens include share/unshare/remove flows
  backed by the existing shared-content API.
- Active workouts request notification permission, schedule a rest-complete
  local notification, cancel it when rest/workout ends, and play the selected
  native timer sound when the visible countdown reaches zero.
- Active workout supersets render as grouped round-by-round cards, with rest
  only after the group boundary and a floating rest bar with +15s/Skip controls.
- `SettingsView.swift` includes admin-only user tools and admin catalog
  management for browsing/searching/removing built-in catalog items plus
  add/edit flows for built-in exercises and programs.

## Backend assumptions

- Production API base URL: `https://smellis-api.fly.dev`
- Auth token header: `X-Auth-Token`
- Login/signup return `{ token, user }`
- `GET /api/catalog` returns `{ programs, exercises }`
- `GET /api/data` returns the user's full state blob
- `PUT /api/data` expects `{ data: <full blob> }`

## Important migration rule

`PUT /api/data` replaces the entire user blob. The starter's `AppData` model
preserves unknown keys so that the iOS app does not silently delete fields added
by the web app. Keep that behavior as you add native features.

The store also mirrors the web app's data-integrity cleanup rules for seven-day
trash retention and custom exercise placeholder relinking.

## Suggested next steps

1. Create the Xcode project and copy these files into the app target.
2. Build in the iOS Simulator and fix any target membership/signing issues.
3. Verify login against the production backend.
4. Run a full regression pass across auth, dashboard, programs/editor, active
   workout, profile/history, nutrition, max tracker, people/shared content,
   settings, and admin catalog.
5. Continue App Store/TestFlight polish, device testing, and any final UX
   refinements discovered during regression.

See `docs/ios-testflight-prep.md` for the TestFlight runbook. See
`docs/ios-swiftui-handoff.md` and `docs/ios-swiftui-screens.md` for the
complete migration specification.
