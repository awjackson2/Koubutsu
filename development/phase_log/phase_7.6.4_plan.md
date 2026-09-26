# Phase 7.6.4 Plan — The video never changes size

## Phase
- **Number:** 7.6.4
- **Name:** Fixed video stage; all chrome overlays it
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
🔧 Fix (Patch on 7.6.0). The video sits in a `VStack` with the transport bar, translation panel, debug panels and
control bar, so any of them appearing, disappearing or changing height resizes the video and moves every
replacement box. Requirement: the video's on-screen size never changes because of UI.

## Immediate Goal
1. The video occupies a fixed 16:9 stage: full container width, top-aligned, height = width × 9/16 (clamped
   to the container). It depends only on the window size.
2. Transport bar, translation panel, OCR list, debug panel and control bar are overlays anchored to the bottom;
   they sit in the space below the stage and cover the video only when taller than that space. Their showing,
   hiding or changing height never changes the stage.
3. The translation panel (panel modes) has a fixed height and scrolls.

## Confirmed Starting Point
7.6.3 (`edb7c49`). `App/UI/RootView.swift`.

## Scope For This Phase
### In
- `VideoStageLayout` (core, Linux-tested): stage rect from container size and aspect.
- `RootView` restructured into a `ZStack` (stage + bottom chrome overlay).
### Out
- Full screen and other QOL (7.8.0).

## Technical Plan
- `VideoStageLayout.stage(containerWidth:containerHeight:aspect:) -> PlaneRect`, aspect default 16:9.
- Video view + `VideoOverlayView` framed to the stage; non-16:9 sources aspect-fit inside it as before
  (`CoordinateMapper` maps within the stage).

## Test Plan
Core `swift test`; CI app build and simulator screenshots.

## Expected Limitations At End Of Phase
- With debug panels on, the bottom chrome covers the lower part of the video in landscape.

## What Comes Next
- 7.8.0 QOL: full screen, quick toggles, history, keep-awake, text size, keyboard shortcuts.

## Summary
The video's size is fixed; everything else floats over the space below it.
