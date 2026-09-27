# Phase 10.3.0 Plan — Compact portrait layout

## Phase
- **Number:** 10.3.0
- **Name:** Compact portrait layout
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
On an iPhone held upright (and narrow iPad windows) the video must sit at the top, full width, with the bars and
panels below it, never over it.

## Immediate Goal
1. `LayoutClass.compactPortrait` windows show: slim housing header, video at full width under it, then transport
   bar, panels and the compact control bar stacked below, panels taking the remaining height.
2. Regular layout unchanged.

## Confirmed Starting Point
10.1.0 (`LayoutClass`, `windowedInsets(for:safe:)`, `@Environment(\.layoutClass)`); 10.2.0 compact bars. RootView
lays out one ZStack for every window: stage from `windowedInsets(safeTop:)`, chrome bottom-anchored over it, panels
150/140 pt.

## Scope For This Phase
### In
- A layout seam in RootView: the body picks a layout per `LayoutClass`; shared pieces (video stage, chrome
  pieces) become reusable. Regular path is the existing code, moved not changed.
- `App/UI/CompactPortraitLayout.swift` (RootView extension): stage from `windowedInsets(for: .compactPortrait)`,
  `MonitorFrame` in a slim variant (header only, no rails, no maker's plate), chrome in a VStack below the stage;
  the translation/Japanese panels share the remaining height (min 88 pt each) instead of fixed heights.
- Full screen in compact portrait: stage centred vertically; tap reveals the chrome as today.
### Out
- Landscape (10.4.0), study mode placement (10.5.0).

## Technical Plan
- `App/UI/RootView.swift`: private state becomes internal so the layout files (extensions) can use it.
- `App/Theme/MonitorFrame.swift`: `compact: Bool` (header only, 24 pt, fixed small fonts).
- Geometry stays in `VideoStageLayout` (rule 6).

## Test Plan
Core tests unchanged (insets covered in 10.1.0). CI build on both simulators; iPhone screenshots portrait.

## Key Decisions
- Portrait chrome is laid out below the stage, not overlaid: the phone has spare height, not spare width.

## Expected Limitations At End Of Phase
- Study panel still uses its 210 pt height until 10.5.0.

## What Comes Next
- 10.4.0, 10.5.0.

## Summary
iPhone portrait shows the video on top and every control and panel below it.
