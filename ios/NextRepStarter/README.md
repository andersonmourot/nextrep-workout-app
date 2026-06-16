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
- `Store/AppStore.swift` for login/session restore, catalog loading, data
  loading, and manual sync.
- `Views/*` with a minimal auth flow, Home dashboard, read-only Programs tab,
  Program Detail navigation, and a first-pass Active Workout screen for set
  logging and rest timing, Finish Workout history persistence, and a Profile
  workout-history viewer with stat cards and logged set details.
- `WorkoutSummaryView.swift` shows the just-finished workout before returning to
  the previous screen.

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
   - Progress charts and body-weight tracking
   - Rest-complete sound/local notification behavior
   - Day detail and edit flows

See `docs/ios-swiftui-handoff.md` and `docs/ios-swiftui-screens.md` for the
complete migration specification.
