# Phase 3.2.0 Plan — OCR bounding-box debug overlay

## Phase
- **Number:** 3.2.0
- **Name:** OCR bounding-box debug overlay
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 8: draw Vision boxes over the video to verify mapping visually.

## Immediate Goal
1. `VideoOverlayView` draws each observation's quad (or rect) via the mapper when `showOCRBoxes` is on.

## Confirmed Starting Point
3.1.0 mapper; `OCRResult` on the main actor.

## Scope For This Phase
### In
- Box drawing
### Out
- Per-word boxes

## Recommended Implementation Direction
Draw quads, not only axis-aligned boxes, so skewed text is visible as Vision reports it.

## Technical Plan
`App/UI/VideoOverlayView.swift`, `App/UI/RootView.swift`.

## Test Plan
Geometry covered by core tests; 1.5.1 fixture tests already verify boxes match on-screen text (IoU ≥ 0.5).

## Key Decisions
- Overlay does not intercept touches.

## Expected Limitations At End Of Phase
- Boxes lag the video by OCR latency (by design).

## What Comes Next
- 3.3.0 translation overlay.

## Summary
OCR boxes visible over the game for mapping verification.
