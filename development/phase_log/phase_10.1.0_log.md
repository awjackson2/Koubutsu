# Phase 10.1.0 Log — iPhone target and layout classes

## Phase
- **Number:** 10.1.0
- **Name:** iPhone target and layout classes
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
Make Koubutsu an iPhone app with a tested layout classifier, and cover the iPhone in CI.

## Major Additions
- `LayoutClass` (KoubutsuCore): regular / compact portrait / compact landscape from the window size
  (height < 500 → compact landscape; width < 600 → compact portrait).
- `VideoStageLayout.windowedInsets(for:safe:)` and `compactHeaderHeight` (24 pt).
- `@Environment(\.layoutClass)` (`App/UI/LayoutEnvironment.swift`), injected by `RootView`.
- `--orientation=portrait|landscape` launch option (`UIWindowScene.requestGeometryUpdate`).
- `LayoutClassTests` (7 tests, 18 cases incl. arguments).

## Major Changes
- `TARGETED_DEVICE_FAMILY` `1,2` for app and tests; iPhone orientations portrait, landscape left/right.
- `Tools/ci_simulator_test.sh` takes `DEVICE=iPad|iPhone`; the iOS workflow runs both as a matrix.
- `Tools/ci_screenshots.sh` + `screenshots.yml` take `device`; on iPhone every series runs in portrait and
  landscape with 5 captures each (`iphone_<orientation>_<series>_t<s>s.png`).
- SDK report lists every mention of external devices in `AVCaptureDevice.h`.

## Progress Made
- `swift test`: 145 tests pass on Linux.

## Key Decisions
- Layout by window size, so narrow iPad windows also get the compact layouts.
- The UI does not use the compact insets yet; iPad layout unchanged.

## Current Limitations
- iPhone still shows the iPad layout until 10.2–10.5.
- Whether an iPhone discovers USB capture devices is still open; headers do not distinguish iPhone from iPad.

## Artifacts Produced
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/LayoutClass.swift`, `VideoStageLayout.swift`,
  `Tests/KoubutsuCoreTests/LayoutClassTests.swift`; `App/UI/LayoutEnvironment.swift`, `App/UI/RootView.swift`,
  `App/Translation/DemoTranslationService.swift`; `Tools/gen_xcodeproj.py`, `Koubutsu.xcodeproj`,
  `Tools/ci_simulator_test.sh`, `Tools/ci_screenshots.sh`, `Tools/sdk_report.sh`, `.github/workflows/ios.yml`,
  `.github/workflows/screenshots.yml`.

## What Comes Next
- 10.2.0 compact bars (in progress in parallel), then 10.3.0 / 10.4.0.

## Summary
Koubutsu builds as an iPhone app, knows which layout a window needs, and CI tests it on an iPhone simulator.
