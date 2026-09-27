# Phase 10.4.0 Plan — Compact landscape layout

## Phase
- **Number:** 10.4.0
- **Name:** Compact landscape layout
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
In iPhone landscape (about 390 pt tall) the video should fill the height and the controls must not cover it
permanently, while staying clear of the Dynamic Island/notch and the home indicator.

## Immediate Goal
1. `LayoutClass.compactLandscape` windows show the stage inside the safe area at full available height.
2. The bars are an overlay revealed by a tap on the video and hidden automatically after 4 s (as full screen does
   today), anchored to the bottom inside the safe area; a small always-visible OSD tab shows that controls exist.
3. Panels (translation list, Japanese list, debug) open over the video's lower part only while the chrome is shown.

## Confirmed Starting Point
10.1.0 insets (`windowedInsets(for: .compactLandscape, safe:)`), 10.2.0 compact bars, 10.3.0 layout seam.

## Scope For This Phase
### In
- `App/UI/CompactLandscapeLayout.swift` (RootView extension).
- Auto-hide chrome reuses `chromeRevealed` / `scheduleChromeHide`; the long press (peek) and study drag keep
  priority on the stage.
- No monitor housing in compact landscape (no room); the stage has a 1 pt paper hairline border.
### Out
- A side rail layout: the space beside a full-height 16:9 stage on a 19.5:9 phone is 60–80 pt per side, mostly
  under the island/notch safe area; not enough for bars.
- Study mode placement (10.5.0).

## Technical Plan
- Geometry via `VideoStageLayout.windowedInsets(for:safe:)` + `framed` only (rule 6).
- `geometry.safeAreaInsets` for all edges; chrome padded by the leading/trailing/bottom safe area.

## Test Plan
CI build on both simulators; iPhone landscape screenshots (overlay, fullscreen, settings).

## Key Decisions
- Overlay over side rail (see Out); the tap-to-reveal model already exists in full screen, so it is familiar.

## Expected Limitations At End Of Phase
- Gesture conflicts are checked on the simulator only until the user's device test.

## What Comes Next
- 10.5.0.

## Summary
iPhone landscape shows the largest possible video with controls a tap away.
