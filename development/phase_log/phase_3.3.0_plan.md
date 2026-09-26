# Phase 3.3.0 Plan — Translation overlay

## Phase
- **Number:** 3.3.0
- **Name:** Translation overlay
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 9: place English near/over the Japanese it translates, readable over gameplay.

## Immediate Goal
1. Core `OverlayLayout`: box at the Japanese block origin, width ≥ block (min 120 pt), font ∝ Japanese line height (0.7×, 12–44 pt), overlap resolution by stacking, clamped to the visible video.
2. `VideoOverlayView` renders placements with a semi-transparent dark background and fade transitions.
3. Display modes: panel, overlay, panel + overlay.

## Confirmed Starting Point
3.2.0 overlay view; Major 2 `DisplayedText`.

## Scope For This Phase
### In
- Layout + rendering + modes
### Out
- Covering/removing Japanese pixels

## Recommended Implementation Direction
Estimated wrapped line count feeds the layout so stacked boxes do not collide after wrapping.

## Technical Plan
`Sources/KoubutsuCore/Overlay/OverlayLayout.swift`, `App/UI/VideoOverlayView.swift`, `App/UI/RootView.swift`.

## Test Plan
`OverlayLayoutTests` (cover box + font, minimum width, stacking, containment).

## Key Decisions
- Overlap is resolved downward; when out of room the box is clamped (visible overlap beats hidden text).

## Expected Limitations At End Of Phase
- Line estimate is heuristic (Latin glyph ≈ 0.52 em).

## What Comes Next
- Major 4 performance.

## Summary
English appears where the Japanese is.
