# NextRepStarter iOS scaffold

This folder is a Phase 0 native SwiftUI starter for rebuilding the existing
NextRep/SMELLIS web app as an iOS app.

It is intentionally source-only. Create a new **iOS App** target in Xcode
(`File > New > Project > iOS > App`, SwiftUI, Swift), then copy the files in
this folder into that target. The code targets iOS 17+ and uses SwiftUI,
Observation, URLSession, and Keychain Services.

## What this starter includes

- `NextRepApp.swift` app entry point.
- `Theme/Theme.swift` with dark theme colors and basic card/button styles.
- `Models/AppModels.swift` with Swift `Codable` models mirroring the current
  web data shape from `src/types.ts` and `src/store.ts`.
- `Models/JSONValue.swift` to round-trip unknown keys in the `/api/data` blob.
- `Services/APIClient.swift` for the existing FastAPI backend.
- `Services/KeychainStore.swift` for JWT persistence.
- `Services/RestTimerNotifier.swift` for rest-complete local notifications.
- `Store/AppStore.swift` for login/session restore, catalog loading, data
  loading, and manual sync.
- `Views/*` with a minimal auth flow, Home dashboard, Programs tab with
  Exercise Library access, Program Detail + Day Detail navigation, Search tab
  people discovery/social sharing, Interval Timer basics, and a first-pass
  Active Workout screen for set logging and rest timing, Finish Workout history
  persistence, and a Profile workout-history viewer with stat cards, dedicated
  Nutrition and Max Tracker pages, body-weight tracking, and logged set details.
- `VisualComponents.swift` provides reusable native progress rings, line charts,
  and metric progress bars used across Dashboard, Profile, Nutrition, Max
  Tracker, Program Detail, and Active Workout.
- `ProgramEditorView.swift` supports first-pass custom program/day/exercise
  creation and editing, including superset group labels.
- `ExerciseEditorView.swift` supports first-pass custom exercise creation and
  editing.
- `WorkoutSummaryView.swift` shows the just-finished workout before returning to
  the previous screen.
- Custom Program and Exercise detail screens include share/unshare/remove flows
  backed by the existing shared-content API.
- Active workouts request notification permission, schedule a rest-complete
  local notification, cancel it when rest/workout ends, and vibrate in-app when
  the visible countdown reaches zero.

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

## Suggested next steps

1. Create the Xcode project and copy these files into the app target.
2. Build in the iOS Simulator and fix any target membership/signing issues.
3. Verify login against the production backend.
4. Confirm the Programs tab renders catalog + custom programs.
5. Continue Phase 1 screens from `docs/ios-swiftui-screens.md`:
   - Exercise photos and richer custom exercise editing
   - Nutrition and Max Tracker detail screens/charts
   - Rest-complete custom sound/background audio polish
   - Superset workout sequencing beyond group labels
   - Per-week program edit flows
   - Full App Store/TestFlight polish pass

See `docs/ios-swiftui-handoff.md` and `docs/ios-swiftui-screens.md` for the
complete migration specification.
