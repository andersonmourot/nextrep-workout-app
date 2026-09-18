---
name: ios-build
description: Build, test, and run the NextRep iOS app (ios/NextRep/NextRep.xcodeproj, scheme NextRep) in the iOS Simulator. Use for any iOS verification or simulator work.
---

# NextRep iOS build & run

Xcode project lives at `ios/NextRep/NextRep.xcodeproj`, scheme `NextRep`.

## Required: DEVELOPER_DIR

`xcode-select` on this machine points at Command Line Tools, so plain
`xcodebuild` fails. Always prefix commands with:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Build (verified working)

```sh
cd ios/NextRep
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project NextRep.xcodeproj -scheme NextRep \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Build products land in `~/Library/Developer/Xcode/DerivedData/NextRep-*/`.
Anything under `xcuserdata/` or `DerivedData/` is gitignored — never commit it.

## Available simulators

`DEVELOPER_DIR=... xcrun simctl list devices available` — iPhone 17 Pro,
iPhone 17 Pro Max, iPhone Air, iPhone 16e are installed.

## Run in the simulator

```sh
# Boot a device (idempotent if already booted)
DEVELOPER_DIR=... xcrun simctl boot "iPhone 17" 2>/dev/null
open -a Simulator

# Install + launch the built app
APP=~/Library/Developer/Xcode/DerivedData/NextRep-*/Build/Products/Debug-iphonesimulator/NextRep.app
DEVELOPER_DIR=... xcrun simctl install booted $APP
DEVELOPER_DIR=... xcrun simctl launch booted com.andersonmourot.NextRep
```

## Tests

`NextRepTests` and `NextRepUITests` targets exist but are template stubs.

```sh
DEVELOPER_DIR=... xcodebuild -project ios/NextRep/NextRep.xcodeproj \
  -scheme NextRep -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Notes

- The app talks to the production API (`https://smellis-api.fly.dev`) via
  `Services/APIClient.swift`; auth token persists in Keychain.
- Repo iOS docs: `ios/NextRep/README.md`, `docs/ios-swiftui-handoff.md`,
  `docs/ios-testflight-prep.md`.
