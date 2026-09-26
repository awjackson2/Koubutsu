# Phase 9.4.0 Plan — Monitor frame around the video

## Phase
- **Number:** 9.4.0
- **Name:** Themed monitor housing around the video stage outside full screen
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
User request: a thematic frame around the video/stream when not in full screen, so the feed reads as part of
Koubutsu rather than a bare rectangle pasted above the controls. Plan amendment to umbrella 9.0.0.

## Immediate Goal
1. Outside full screen the video sits inside a surveillance-monitor housing: header strip (channel tag, source
   name, running clock, record dot), side tick rails, a bottom rail, a bezel hairline and red HUD corner ticks.
2. Full screen keeps today's edge-to-edge stage; switching animates the stage between the two rectangles.
3. The windowed stage still depends only on the window size (never on chrome, panels or settings; 7.6.4).

## Confirmed Starting Point
`024312b` (9.3.0). `VideoStageLayout.stage` (full width, top-aligned 16:9).

## Scope For This Phase
### In
- Core: `VideoStageLayout.StageInsets`, `VideoStageLayout.framed(containerWidth:containerHeight:insets:aspect:)`,
  `VideoStageLayout.windowedInsets(safeTop:)`; tests.
- App: `App/Theme/MonitorFrame.swift`; `RootView` picks the framed stage outside full screen.
### Out
- User-adjustable frame size or style (the video size is not user-adjustable, 7.6.4).
- Frame in full screen.

## Technical Plan
- `framed`: fit the aspect inside the container minus insets, horizontally centred, top at `insets.top`.
- Insets: top = max(safe-area top, 24) + 30 (header), sides 18, bottom 16.
- `MonitorFrame(stage:)`: raised-ink housing with grain/scanlines, tick rails drawn with `Canvas`, clock via a
  1 s `TimelineView`; no work per video frame. Hit testing off.
- Stage rectangle and frame animate with `K.reveal` on `isFullScreen`.

## Test Plan
Core `swift test` (framed stage geometry); CI iOS build; screenshot series (default series show the frame,
fullscreen series shows none).

## Expected Limitations At End Of Phase
- Windowed video is slightly smaller than before (about 3% narrower on an 11" iPad).

## What Comes Next
- Major 9 logs.

## Summary
The feed looks like a Koubutsu monitor, not a pasted rectangle.
