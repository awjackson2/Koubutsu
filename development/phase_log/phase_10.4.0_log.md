# Phase 10.4.0 Log — Compact landscape layout

## Phase
- **Number:** 10.4.0
- **Name:** Compact landscape layout
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
In iPhone landscape (and short iPad windows) the video fills the available height inside the safe area, and the
bars and panels are an overlay a tap away instead of covering the video permanently (`phase_10.4.0_plan.md`).

## Major Additions
- Core: `VideoStageLayout.overlayChromeFraction` (0.6), `minimumOverlayPanelHeight` (44),
  `overlayPanelBudget(stageHeight:barsHeight:)` (height the panels may share so bars + panels stay within 60 % of
  the stage; zero below 44 pt) and `overlayChromeInsets(safe:)` (leading/trailing/bottom safe area). 3 tests in
  `LayoutClassTests`.
- `App/UI/CompactLandscapeLayout.swift` replaces the placeholder:
  - stage from `windowedInsets(for: .compactLandscape, safe:)` + `framed`, windowed and full screen alike; no
    monitor housing; a 1 pt `K.paper` hairline just outside the stage outside full screen;
  - chrome (transport bar, panels, control bar; the study panel while study mode is active) as a bottom-anchored
    overlay padded by `overlayChromeInsets`; panels share `overlayPanelBudget` (nil heights inside a bounded,
    clipped frame) and are dropped when the budget is zero;
  - a tap on the stage toggles the chrome, any tap on the chrome restarts the 4 s auto-hide timer, and the timer is
    never started (and a pending one is cancelled) while VoiceOver runs;
  - while the chrome is hidden (outside full screen) an OSD tab (pixel chevron up + "CONTROLS") sits at the bottom
    edge of the stage; it is a 44 pt button, `accessibilityLabel("Show controls")`, that reveals the chrome.

## Major Changes
- `RootView` (minimal, localized):
  - `@Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled` (internal, read by the layout extension);
  - `interactiveStage(_:onTap:)`: optional tap handler replacing the default `stageTapped()`; the regular and
    compact portrait layouts call it without one, so their behaviour is unchanged.
  - `stageTapped()` / `scheduleChromeHide()` / `showsChrome` are untouched; compact landscape has its own
    `compactLandscapeStageTapped()`, `revealCompactLandscapeChrome()` and `scheduleCompactLandscapeChromeHide()`
    (in the layout file) sharing `chromeRevealed` / `hideChromeTask`.

## Progress Made
- `swift test`: 148 tests pass on Linux.

## Key Decisions
- Separate compact landscape tap/hide functions instead of widening the `isFullScreen` guards in `RootView`: the
  iPad (regular) path, including its full-screen behaviour under VoiceOver, stays byte-for-byte the same.
- Full screen keeps the same safe-area stage as windowed (the plan's "same as windowed minus the hairline"); the
  status bar is already hidden in iPhone landscape, so the difference is the hairline and the OSD tab.
- Bar heights for the panel budget come from `KIconButtonStyle.minimumTarget` (control bar 44 + 4 pt padding,
  transport bar 44, counted only for file sources) rather than measuring, to keep the layout stateless.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge.
- `RootView`'s `GeometryReader` ignores only the top safe area, so the proxy reports zero leading/trailing/bottom
  insets and its frame is already inside them; the stage still clears the island/notch and home indicator (by the
  6/4 pt floors inside the safe frame), and the chrome padding is then zero. Behaviour is correct either way;
  screenshots should confirm.
- The study panel keeps its fixed 210 pt height (about 57 % of an iPhone 15 landscape stage) until 10.5.0.
- The debug panel is not scrollable; when the budget is smaller than it, the panel area is clipped.
- Gesture interplay (tap vs. long-press peek vs. study drag vs. system edge gestures) checked by reasoning only
  until simulator screenshots and the user's device test.

## Artifacts Produced
- `App/UI/CompactLandscapeLayout.swift`, `App/UI/RootView.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/VideoStageLayout.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/LayoutClassTests.swift`.

## What Comes Next
- CI build on both simulators; iPhone landscape screenshots (overlay, full screen, settings).
- 10.5.0 study mode on compact layouts.

## Summary
iPhone landscape now shows the largest video that fits inside the safe area, framed by a paper hairline, with the
bars and panels as an auto-hiding overlay capped at 60 % of the video's height, a visible "CONTROLS" tab while
they are hidden, and no auto-hide while VoiceOver runs; the iPad layout is unchanged.
