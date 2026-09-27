# Phase 10.3.0 Log — Compact portrait layout

## Phase
- **Number:** 10.3.0
- **Name:** Compact portrait layout
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
See `phase_10.3.0_plan.md` (and its Amendments). On an iPhone held upright, and in narrow iPad windows, the video
sits at the top at full width under a slim housing header, and the bars and panels are stacked below it, never
over it. The iPad (regular) layout is unchanged.

## Major Additions
- Core (`VideoStageLayout`): `compactHeader(above:)`, `chromeRegion(below:containerWidth:containerHeight:gap:bottomInset:)`,
  `compactPanelMinHeight(regionHeight:)` (88 pt per panel when two panels and the bars fit, else 0),
  `centered(containerWidth:containerHeight:insets:aspect:)`, constants `compactChromeGap` (6),
  `compactPanelMinHeight` (88), `compactBarsAllowance` (100). 7 tests in `CompactPortraitLayoutTests` (iPhone SE,
  15, Pro Max and a Slide Over width; no overlap between stage and chrome region; centred full screen).
- App: `CompactMonitorFrame` (in `MonitorFrame.swift`): housing texture, 3 pt bezel with red corner ticks, one-line
  header (CH-01 tag, source, clock) in fixed 10–11 pt type inside the 24 pt `compactHeaderHeight`; no rails, no
  maker's plate.
- App: `compactPortraitLayout` (`App/UI/CompactPortraitLayout.swift`) replaces the 10.3.0 seam placeholder.
  Windowed: stage from `windowedInsets(for: .compactPortrait, safe:)`, chrome in `chromeRegion(below:)` —
  transport bar, `panels(translationHeight: nil, recognizedHeight: nil)` sharing the remaining height (min 88 pt
  each where it fits), control bar at the bottom above the home indicator; the housing shows through as filler
  when no sharing panel is enabled. Study mode: the study panel directly under the video in place of the
  bars and panels. Full screen: stage `centered` at full width; the tap-revealed chrome (existing
  `showsChrome`/`chromeRevealed`/`scheduleChromeHide`) is bottom-anchored in the region below the video.

## Major Changes
- Layout seam in `RootView` (commit `e932cd2`, part of this phase): the body picks `regularLayout`,
  `compactPortraitLayout` or `compactLandscapeLayout` by `LayoutClass`; shared pieces (`interactiveStage`,
  `transportBar`, `controlBar`, `studyPanel`, `panels(translationHeight:recognizedHeight:)`, `chrome`) became
  internal so the layout files can compose them. Regular path moved, not changed.
- `MonitorClock` gains `fontSize` (default 14, so the regular housing is identical; the dot scales with it).
- No changes to `RootView.swift` in the implementation commit.

## Progress Made
- `swift test` (KoubutsuCore, Linux): 152 tests in 29 suites pass.
- App code written against existing SwiftUI APIs only (`GeometryProxy.safeAreaInsets`, `ignoresSafeArea(edges:)`,
  `frame(minHeight:)` on a `Group`, `simultaneousGesture`).

## Key Decisions
- Chrome below the stage, not overlaid: the phone has spare height, not spare width.
- Panel minimums are dropped (not overflowed) when the region is too short, so the chrome never pushes over the
  video in short narrow windows.
- A separate `CompactMonitorFrame` instead of a flag on `MonitorFrame` keeps the regular housing's code untouched.
- The chrome region's bottom subtracts `safeAreaInsets.bottom`; the root view respects the bottom safe area, so
  this is normally 0 and the control bar already sits above the home indicator; the housing texture alone runs
  on under it.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge. No iPhone screenshots taken yet.
- The minimum panel height is applied to every view in `panels(...)` (also the debug panel and the overlay-mode
  status line), which pads a short status line to 88 pt.
- Study panel keeps its fixed 210 pt height until 10.5.0.
- In full screen with a sharing panel enabled, the revealed chrome fills the whole region below the video.

## Artifacts Produced
- `App/UI/CompactPortraitLayout.swift`, `App/Theme/MonitorFrame.swift`
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/VideoStageLayout.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/CompactPortraitLayoutTests.swift`
- `development/phase_log/phase_10.3.0_plan.md` (Amendments), `development/phase_log/phase_10.3.0_log.md`

## What Comes Next
- macOS CI build and `device=iphone` portrait screenshots; on-device check.
- 10.4.0 (landscape), 10.5.0 (study mode on compact layouts).

## Summary
iPhone portrait now shows the video at the top in a slim monitor housing with the transport bar, panels and control
bar stacked below it; full screen centres the video and reveals the same chrome beneath it on a tap. The geometry
lives in `VideoStageLayout` with Linux tests; the iPad layout is unchanged.
