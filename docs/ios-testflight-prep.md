# iOS TestFlight preparation checklist

Use this checklist after the SwiftUI app builds and the final in-app regression
pass succeeds locally in Xcode.

## 1. Confirm local repo and files

```bash
cd ~/nextrep-workout-app
git pull origin cursor/ios-swiftui-starter-2b9d
```

In Xcode:

```text
Cmd + Shift + K
Cmd + B
```

Confirm the project is using the latest files from `ios/NextRepStarter`.

## 2. App identity

In the Xcode target settings:

```text
Display Name: NextRep
Bundle Identifier: use a real reverse-DNS id, e.g. com.yourcompany.nextrep
Version: 1.0
Build: start at 1, then increment for every TestFlight upload
Team: select your Apple Developer Team
Signing: Automatic is recommended for the first TestFlight build
```

Every upload for the same version needs a higher build number:

```text
1.0 (1)
1.0 (2)
1.0 (3)
```

## 3. Deployment target and capabilities

Recommended starting point:

```text
Minimum iOS: iOS 17 or later
Interface: SwiftUI
Language: Swift
```

Capabilities currently expected:

```text
Push Notifications: not required
Background Modes: not required for the current local-notification timer flow
Keychain Sharing: not required unless you add app groups/shared keychain later
Associated Domains: not required unless reset links/deep links are added later
```

Local notifications are requested at runtime by the app for rest timers.

## 4. App icon and launch assets

Before archiving:

```text
- Add production app icons to Assets.xcassets/AppIcon
- Confirm there are no missing icon slots reported by Xcode
- Confirm the app name renders correctly under the icon
```

You can upload a TestFlight build before all marketing screenshots are final,
but the app icon should be real before external testing.

## 5. Backend configuration

The native API client currently points at:

```text
https://smellis-api.fly.dev
```

Before TestFlight:

```text
- Confirm this is the intended production backend
- Confirm login/signup works from a real device on cellular and Wi-Fi
- Confirm /api/catalog loads
- Confirm /api/data sync persists after force-quitting and reopening
```

## 6. Final smoke test on a real iPhone

Run at least this quick pass before archiving:

```text
Auth:
- login
- logout
- login again

Home / Programs:
- set active program
- start workout
- finish workout
- confirm history appears

Program Editor:
- create custom program
- edit week 2
- save

Exercise Library:
- create custom exercise
- edit built-in exercise override
- restore default

Timer:
- preview sound
- short countdown completion sound

Profile:
- body weight
- nutrition
- max tracker

Settings:
- theme mode
- accent color
- legal screens
```

## 7. Archive and upload

In Xcode:

```text
1. Select a real device or "Any iOS Device" as the run destination
2. Product > Archive
3. Wait for Organizer to open
4. Select the archive
5. Distribute App
6. App Store Connect
7. Upload
8. Let Xcode manage signing for the first upload
9. Submit
```

If the upload fails:

```text
- Read the Organizer error text
- Fix signing/icon/bundle/build-number issues
- Increment build number if Xcode already uploaded a build
- Archive again
```

## 8. App Store Connect / TestFlight setup

In App Store Connect:

```text
1. Create the app record if it does not exist
2. Match the Bundle Identifier from Xcode
3. Wait for the uploaded build to process
4. Add internal testers
5. Fill in test information / beta notes
6. Start internal testing
```

Suggested beta notes:

```text
Native SwiftUI TestFlight build for NextRep. Please test login, program
editing, active workout logging, timer sounds, profile/history, nutrition,
max tracker, people/shared content, settings/theme, and admin catalog if your
account has admin access.
```

## 9. Iterating after TestFlight

TestFlight does not freeze development.

```text
1. Test build 1
2. Fix issues
3. Increment build number
4. Archive/upload build 2
5. Repeat as needed
```

Keep `Version` stable until you are ready to market a new app version. Increment
`Build` for every upload.

## 10. Before external testers or App Review

Before expanding beyond internal testers:

```text
- Privacy policy URL is ready
- Support/contact email is ready
- App description and screenshots are drafted
- Any required Health/Fitness disclaimers are visible in-app
- No test-only accounts/content are bundled in the app
- Backend rate limits/logging are ready for testers
```

