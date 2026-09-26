# Phase 1.1.0 Plan — Project Bootstrap

## Phase
- **Number:** 1.1.0
- **Name:** Project bootstrap (Xcode project, core package, CI, empty app shell)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Create the native iPad app and the build/verification infrastructure. The container has no Xcode, so this
phase also establishes macOS CI as the compiler of record and a Linux path for core-logic tests. Highest-risk
item in Major 1: an `.xcodeproj` authored without Xcode.

## Immediate Goal
1. `Koubutsu.xcodeproj` with an iPad app target `Koubutsu` and a hosted unit-test target `KoubutsuTests`, using file-system-synchronized groups (`App/`, `AppTests/`).
2. Local Swift package `Packages/KoubutsuCore` linked into the app; builds and tests on Linux.
3. Shared scheme `Koubutsu` (build + test).
4. SwiftUI app shell that launches and shows a placeholder root view.
5. CI: `core-linux.yml` (`swift test` in a Swift container) and `ios.yml` (macOS: Xcode selection, SDK report artifact, simulator build + test).

## Confirmed Starting Point
- `README.md`, `CLAUDE.md`, `.gitignore`, `development/phase_log/*` only.
- Swift 6.3.1 toolchain installed locally at `/opt/swift` (Linux) for core tests.

## Scope For This Phase
### In
- Project file, scheme, app shell, core package skeleton with one smoke test, CI workflows, `Tools/sdk_report.sh`.
### Out
- Any pipeline types (1.2.0), video (1.3.0), deployment-target decision (1.1.1).

## Recommended Implementation Direction
- `objectVersion = 77` project with `PBXFileSystemSynchronizedRootGroup` so new Swift files need no pbxproj edits.
- `GENERATE_INFOPLIST_FILE = YES` with `INFOPLIST_KEY_*` settings; no hand-written Info.plist.
- Deployment target provisionally `18.0`; 1.1.1 finalizes from the SDK report.
- Tests use Swift Testing (`import Testing`) in both the package and the app test target.
- CI selects the newest installed Xcode on the runner and picks an available iPad simulator dynamically.

## Technical Plan
- `Koubutsu.xcodeproj/project.pbxproj`, `Koubutsu.xcodeproj/xcshareddata/xcschemes/Koubutsu.xcscheme`.
- `App/KoubutsuApp.swift`, `App/UI/RootView.swift`.
- `AppTests/AppSmokeTests.swift`.
- `Packages/KoubutsuCore/Package.swift`, `Sources/KoubutsuCore/KoubutsuCore.swift`, `Tests/KoubutsuCoreTests/SmokeTests.swift`.
- `.github/workflows/core-linux.yml`, `.github/workflows/ios.yml`, `Tools/sdk_report.sh`, `Tools/ci_simulator.sh`.

## Test Plan
- Local: `swift test` in `Packages/KoubutsuCore`.
- CI: both workflows green on the pushed commit.

## Key Decisions
- Synchronized groups over per-file references — robust hand authoring, less merge churn.
- Swift Testing over XCTest — modern, runs on Linux toolchain and Xcode 16+.

## Expected Limitations At End Of Phase
- No visual verification of the app beyond CI build/test.

## What Comes Next
- 1.1.1 SDK report analysis and deployment target.

## Summary
Stand up the Xcode project, core package, and dual-platform CI so every later phase has a compiler and a test gate.
