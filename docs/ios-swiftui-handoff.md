# NextRep — Native iOS (SwiftUI) Build Handoff

This document hands off the NextRep workout app to a **native SwiftUI rewrite**, built on
your Mac with **Devin CLI + Xcode**. The existing React/Vite web app and the FastAPI
backend stay exactly as-is; the SwiftUI app is a new client that talks to the **same
backend API**. Nothing in the web app needs to change.

---

## 1. Goal & why native

Rebuild the iOS experience natively to unlock what a web app/PWA can't do on iPhone:

- **Background audio** — the rest-timer bell/beeps play even when the app is backgrounded
  or the phone is locked (the limitation you hit on the web app). This is the headline win.
- **Reliable local notifications** for rest-timer-done.
- **Apple Watch app** — rest timer with wrist haptics, mark-set-done, glance at the workout.
- **Live Activity / Dynamic Island** — live rest countdown on the lock screen.
- **HealthKit** — write workouts to Apple Health, optionally read heart rate.
- **App Store / TestFlight** distribution instead of "add to home screen."

---

## 2. Architecture

```
┌─────────────────────────┐        HTTPS / JSON         ┌──────────────────────────┐
│  SwiftUI app (new)      │ ──────────────────────────► │  FastAPI backend (exists) │
│  - Views (SwiftUI)      │   X-Auth-Token: <JWT>       │  https://<prod-api>       │
│  - ViewModels (@Observable)                           │  SQLite (smellis.db)      │
│  - APIClient (async/await URLSession)                 └──────────────────────────┘
│  - Codable models       │
│  - AVAudioSession (bg audio)
└─────────────────────────┘
```

**Key insight about the backend:** it is almost entirely a **single per-user JSON blob**.
Aside from auth and social/sharing endpoints, the whole app state (programs, exercises,
history, notes, cues, active workout, theme) is stored as one JSON document per user via
`GET /api/data` and `PUT /api/data`. So the SwiftUI app:

1. Logs in → gets a JWT.
2. `GET /api/data` → decodes the blob into Swift models (the app's source of truth).
3. Mutates locally, then `PUT /api/data` with the full blob to persist (debounced).
4. Uses the social endpoints only for discover/follow/shared programs.

This makes the rewrite mostly a **UI + local-state** job, not a backend integration
marathon. Mirror the web app's `store.ts` shape in Swift and you're 80% there.

---

## 3. Backend API reference

**Base URL:** the deployed backend (the web app's `.env.production` `VITE_API_URL`).
Local dev backend runs at `http://127.0.0.1:8000`.

**Auth:** send the token on every authenticated request as a header.
Preferred: `X-Auth-Token: <jwt>` (the `Authorization` header is reserved for the
tunnel/proxy's basic auth in some deploys). `Authorization: Bearer <jwt>` also works for
local/dev. Token is a JWT returned by login/signup.

### Auth & account
| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/signup` | `{name, email, password}` | `{token, user}` |
| POST | `/auth/login` | `{email, password}` | `{token, user}` |
| POST | `/auth/password` | `{current_password, new_password}` | ok |
| POST | `/auth/forgot-password` | `{email}` | generic ok (no account-existence leak) |
| POST | `/auth/reset-password` | `{token, new_password}` | ok |
| GET | `/me` | — | `{id, name, email, is_admin}` |

`user` shape (`PublicUser`): `{ id, name, email, is_admin }`.

### App state (the big one)
| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/api/data` | — | the user's full state blob (object) |
| PUT | `/api/data` | `{data: {...}}` | persists the full blob |

### Social / sharing
| Method | Path | Notes |
|---|---|---|
| GET | `/api/users/search?q=` | discover users → `[{id,name,color,following,program_count,exercise_count}]` |
| POST | `/api/users/{user_id}/follow` | follow |
| DELETE | `/api/users/{user_id}/follow` | unfollow |
| GET | `/api/following` | who you follow |
| GET | `/api/users/{user_id}/programs` | `{user, programs[]}` |
| GET | `/api/users/{user_id}/exercises` | `{user, exercises[]}` |
| PUT | `/api/programs/{program_id}` | upsert a shared program `{program: {...}}` |
| GET | `/api/programs/{program_id}` | fetch shared program |
| POST | `/api/programs/batch` | `{ids: [...]}` → refresh followed programs (sync) |
| POST | `/api/programs/{program_id}/add` | add (follow) a program |
| DELETE | `/api/programs/{program_id}/member` | remove a followed program |
| PUT/GET | `/api/exercises/{exercise_id}` | same pattern as programs |
| POST | `/api/exercises/batch` | `{ids: [...]}` |
| POST/DELETE | `/api/exercises/{exercise_id}/add` / `/member` | add / remove shared exercise |

Admin-only (email allow-list): `GET /api/admin/users`,
`POST /api/admin/users/{id}/reset-password`. Probably skip in v1.

**Sharing/sync semantics to preserve:** programs and exercises carry `ownerId`,
`ownerName`, `collaborative`, and `version` (epoch-ms). "Follow" keeps a program in sync
with the creator (newest `version` wins); "Duplicate" makes an independent copy. The
`*/batch` endpoints are how the client refreshes followed items.

**Privacy rule (important):** per-exercise **cues (sub-headers)** and **notes** are
stored in the user's own blob (`exerciseSubheaders`, `exerciseNotes`) and are **never
shared** — do not include them when publishing/sharing a program or exercise.

---

## 4. Data model (Swift `Codable`, mirrors `src/types.ts`)

```swift
struct Exercise: Codable, Identifiable {
    let id: String
    var name: String
    var primaryMuscle: String          // enum-able: Chest, Back, Legs, ...
    var secondaryMuscles: [String]
    var equipment: String              // Barbell, Dumbbell, Machine, Cable, Bodyweight, Kettlebell, Bands
    var difficulty: String             // Beginner | Intermediate | Advanced
    var instructions: [String]
    var tips: [String]
    var ownerId: String?
    var collaborative: Bool?
    var version: Int?                  // epoch ms
}

struct PlannedExercise: Codable {
    var exerciseId: String
    var name: String?                  // free-text for user-typed exercises
    var sets: Int
    var reps: String                   // e.g. "8-12"
    var restSec: Int
    var notes: String?
    var groupId: String?               // shared id = superset/triset (back-to-back, rest after round)
}

struct ProgramDay: Codable, Identifiable {
    let id: String
    var name: String
    var focus: String
    var exercises: [PlannedExercise]
}

struct Program: Codable, Identifiable {
    let id: String
    var name: String
    var category: String               // Bodybuilding, Strength, HIIT, Powerlifting, Functional, Bodyweight
    var level: String                  // Beginner | Intermediate | Advanced
    var coach: String
    var durationWeeks: Int
    var daysPerWeek: Int
    var days: [ProgramDay]
    // weekOverrides, ownerId, ownerName, collaborative, version ...
}

struct SetLog: Codable { var weight: Double; var reps: Int; var completed: Bool }

struct ActiveWorkout: Codable {
    var programId: String
    var dayId: String
    var week: Int?
    var startedAt: Double               // epoch ms; elapsed derived from this
    var sets: [[SetLog]]
    var exerciseIds: [String]          // 1:1 with `sets`
}

// The whole /api/data blob:
struct AppData: Codable {
    var themeColor: String?            // default "#355e3b" (the app's green)
    var customPrograms: [Program]
    var customExercises: [Exercise]
    var activeWorkout: ActiveWorkout?
    var exerciseNotes: [String: String]       // private, never shared
    var exerciseSubheaders: [String: String]  // the cues — private, never shared
    var history: [/* workout history entries */]
    // ...plus whatever else store.ts holds; decode loosely and round-trip unknown keys.
}
```

> Tip: decode the blob into your models but **round-trip unknown keys** (keep a raw
> `[String: JSONValue]` alongside, or re-fetch-merge) so a SwiftUI client never drops
> fields the web app added. Safest is to treat the web `store.ts` as the schema source of
> truth and keep the Swift structs in lockstep.

There is a built-in library of stock programs/exercises in the web app
(`src/data/…`). For the native app, either port that seed data into the bundle or expose
it from the backend — decide early; the web app currently ships it client-side.

---

## 5. Screen map (current web → SwiftUI)

| Web (`src/pages`) | SwiftUI view | Notes |
|---|---|---|
| `Login` / `Signup` / forgot/reset | `AuthFlowView` | store JWT in Keychain |
| `Programs` (list + search) | `ProgramsListView` | search matches name, coach, category, level, **days/week** |
| `ProgramDetail` | `ProgramDetailView` | days overview; Duplicate vs **Follow** popup |
| `ProgramEditor` | `ProgramEditorView` | day/exercise editing, **supersets** (link/unlink, A1/A2/A3), per-exercise **cue button** |
| `DayReview` | `DayDetailView` + `DayEditView` | display + edit; cue button next to notes |
| `Workout` (active) | `ActiveWorkoutView` | **the priority screen** — sets/reps logging, rest timer + bell, supersets round-by-round |
| `Timer` (interval) | `IntervalTimerView` | TABATA/EMOM/AMRAP, **Add Sets** (sets + rest-between-sets), "Set X of N" |
| `People` | `DiscoverView` | search users, follow, add/**Remove** programs |
| `Progress` / profile | `ProfileView` | history/stats, theme color |
| `Settings` | `SettingsView` | change password, log out ("Confirm"), admin users (optional) |

Recurring components: `ExerciseNotesButton` (pencil), `ExerciseCueButton` + inline cue
(the recent refactor — empty cue = icon button next to notes; filled = inline line under
title, click-to-edit), bottom tab nav.

---

## 6. Phased roadmap (suggested for the CLI session)

**Phase 0 — Project + plumbing**
- New SwiftUI app (iOS 17+, `@Observable`/Observation). Add an `APIClient` (async
  URLSession), `KeychainStore` for the JWT, and `AppData` Codable models.
- Auth flow → `GET /api/data` → render a read-only Programs list. Prove the round-trip.

**Phase 1 — Core read/run**
- Programs list + detail, Day detail, and the **Active Workout** screen with set logging
  and the rest timer.
- Wire `PUT /api/data` (debounced) so logged sets/active workout persist.

**Phase 2 — The native payoff: background audio + timer**
- Configure `AVAudioSession` (`.playback`, `.mixWithOthers` if you want to layer over
  music; note the silent-switch tradeoff we discussed) and schedule the bell so it fires
  in the background / on lock screen.
- Local notification on rest-complete as a backstop.
- Interval timer (TABATA/EMOM/AMRAP) with Add Sets.

**Phase 3 — Editing + social**
- Program editor (incl. supersets), cues + notes, Discover/Follow/Duplicate, sync via the
  `*/batch` endpoints.

**Phase 4 — Apple Watch (optional, the thing Capacitor couldn't do)**
- watchOS target: rest timer with haptics, mark-set-done, current-exercise glance,
  syncing with the phone via WatchConnectivity.

**Phase 5 — Polish + ship**
- Live Activity/Dynamic Island rest countdown, HealthKit write, widgets.
- Signing with your Apple Developer account → TestFlight → App Store.

---

## 7. Gotchas / things to preserve

- **Auth header:** prefer `X-Auth-Token`; `Authorization: Bearer` may be consumed by the
  proxy in prod.
- **Whole-blob PUT:** `PUT /api/data` replaces the entire blob — read-modify-write, and
  don't drop unknown keys.
- **Cues & notes are private** — never include them in shared programs/exercises.
- **Supersets:** consecutive `PlannedExercise`s with the same non-empty `groupId` are one
  group; rest only after the last in each round (last exercise's `restSec`).
- **Versioning:** shared programs/exercises sync by `version` (epoch-ms), newest wins.
- **Theme color** default is `#355e3b` (the app's green).
- **Admin** is an email allow-list on the backend (`ADMIN_EMAILS`), not a DB flag.

---

## 8. Kickoff prompt for Devin CLI (paste this on your Mac)

> I want to build a **native SwiftUI iOS app** for an existing workout product called
> NextRep. There's an existing FastAPI backend I must reuse — it stores almost all app
> state as a single per-user JSON blob via `GET/PUT /api/data`, with JWT auth sent as the
> `X-Auth-Token` header. Use the attached handoff doc as the spec for the API, data model,
> and screen map.
>
> Start with **Phase 0**: scaffold an iOS 17 SwiftUI app in Xcode, add an async
> `APIClient` (URLSession), Keychain JWT storage, and `Codable` models for the `/api/data`
> blob. Implement login → `GET /api/data` → show a read-only Programs list. Build and run
> it in the iOS Simulator and show me. Then we'll move to the Active Workout screen and
> background audio.

(Keep this doc in the repo or alongside the Xcode project so the CLI session can read it.)
