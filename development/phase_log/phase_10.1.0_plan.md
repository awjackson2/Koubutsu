# Phase 10.1.0 Plan — iPhone target and layout classes

## Phase
- **Number:** 10.1.0
- **Name:** iPhone target and layout classes
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
Make the app an iPhone app (not only a sideloaded iPad app) and give the UI one place to ask which layout applies,
so later Minors (10.2–10.6) build compact layouts on a tested base. Capture the current iPhone breakage.

## Immediate Goal
1. The app and tests build for iPhone and iPad; iPhone portrait and landscape are supported.
2. `LayoutClass` (KoubutsuCore) classifies a window as regular / compact portrait / compact landscape, with
   stage insets per class; tested on Linux.
3. `@Environment(\.layoutClass)` is available to every view; the iPad layout is unchanged.
4. CI builds and tests on an iPad and an iPhone simulator; screenshots can target an iPhone in both orientations.

## Confirmed Starting Point
`Tools/gen_xcodeproj.py` sets `TARGETED_DEVICE_FAMILY = 2`; only iPad orientations. `VideoStageLayout` has
regular `windowedInsets(safeTop:)` only. `Tools/ci_simulator_test.sh` and `Tools/ci_screenshots.sh` pick iPad
simulators. No launch option sets orientation.

## Scope For This Phase
### In
- Device family `1,2`; iPhone orientations portrait, landscape left/right (no upside down).
- `LayoutClass.classify(width:height:)`: compact landscape when height < 500; else compact portrait when
  width < 600; else regular.
- `VideoStageLayout.windowedInsets(for:safe:)`: regular as today; compact portrait with a slim 24 pt header and
  6 pt side bezels clear of the safe area; compact landscape inside the safe area with no header.
- `LayoutEnvironment.swift`: `EnvironmentValues.layoutClass`; RootView injects it from the window size.
- `--orientation=portrait|landscape` launch option via `UIWindowScene.requestGeometryUpdate` (screenshots).
- CI: `ci_simulator_test.sh` takes `DEVICE=iPad|iPhone`; the iOS workflow runs both. Screenshot workflow
  `device` input; on iPhone each series is captured in portrait and landscape.
### Out
- Using the compact insets in the UI (10.3.0/10.4.0); bar changes (10.2.0).

## Recommended Implementation Direction
Classify by window size, not idiom: narrow iPad windows get compact layouts too.

## Technical Plan
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/LayoutClass.swift` (new), `VideoStageLayout.swift`.
- `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/LayoutClassTests.swift` (new).
- `App/UI/LayoutEnvironment.swift` (new), `App/UI/RootView.swift` (inject only), `LaunchOptions` in
  `App/Translation/DemoTranslationService.swift`, `App/KoubutsuApp.swift` or RootView for the orientation request.
- `Tools/gen_xcodeproj.py` + regenerated `Koubutsu.xcodeproj`, `Tools/ci_simulator_test.sh`,
  `Tools/ci_screenshots.sh`, `.github/workflows/ios.yml`, `.github/workflows/screenshots.yml`.

## Test Plan
`swift test` (LayoutClass at iPhone SE/15/Pro Max sizes both orientations, iPad sizes, Split View widths; insets).
CI iOS on both simulators. On-demand iPhone screenshots as the baseline.

## Key Decisions
- Thresholds 500/600 pt: every iPhone landscape height is ≤ 440 pt; every iPad full-screen width ≥ 744 pt.
- No upside-down portrait on iPhone (Apple's default for Face ID iPhones).

## Expected Limitations At End Of Phase
- iPhone still shows the iPad layout; the baseline screenshots record that.

## What Comes Next
- 10.2.0 bars, 10.3.0 portrait, 10.4.0 landscape.

## Summary
The app becomes an iPhone app with a tested layout classifier and CI coverage on an iPhone simulator.
