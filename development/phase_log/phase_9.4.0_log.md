# Phase 9.4.0 Log — Monitor frame around the video

## Phase
- **Number:** 9.4.0
- **Name:** Themed monitor housing around the video stage outside full screen
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_9.4.0_plan.md` (user request; amendment to umbrella 9.0.0).

## Major Additions
- Core: `VideoStageLayout.StageInsets`, `framed(containerWidth:containerHeight:insets:aspect:)`,
  `windowedInsets(safeTop:)`, `headerHeight`; `stage` now delegates to `framed` with zero insets. 3 tests.
- App: `App/Theme/MonitorFrame.swift` — housing (grain, scanlines), header (CH-01 tag, source, `MonitorClock`),
  tick rails (`Canvas`), recessed bezel, red corner ticks.

## Major Changes
- `RootView` uses the framed stage outside full screen, the edge-to-edge stage in full screen, animated with
  `K.reveal`.

## Progress Made
- CI green on `26b4869` (iOS, IPA, Core, Screenshots). Screenshots showed the header crowding the status bar
  and an empty black area under the housing in portrait → 9.4.1.

## Key Decisions
- Fixed insets, not chrome-dependent: the video still never moves when panels change (7.6.4).
- Clock ticks once a second; nothing in the frame runs per video frame.

## Current Limitations
- Windowed video is slightly smaller than before (about 3% narrower on an 11" iPad).

## Artifacts Produced
- `App/Theme/MonitorFrame.swift`, `App/UI/RootView.swift`, `VideoStageLayout.swift`, `VideoStageLayoutTests.swift`.

## What Comes Next
- 9.4.1.

## Summary
The feed sits in a Koubutsu monitor instead of a bare rectangle.
