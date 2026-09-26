# Phase 7.6.4 Log — The video never changes size

## Phase
- **Number:** 7.6.4
- **Name:** Fixed video stage; all chrome overlays it
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
🔧 Fix (Patch on 7.6.0): the video's on-screen size must never change because of UI.

## Major Additions
- `VideoStageLayout.stage(containerWidth:containerHeight:aspect:)` (core): full width, top-aligned 16:9 stage.

## Major Changes
- `RootView`: `ZStack` of the fixed stage (video + replacement overlay + error message) and a bottom-anchored
  chrome stack (transport bar, translation panel, OCR list, debug panel, control bar) that overlays the space
  below the stage.
- Translation panel (panel modes) in a fixed 150 pt scroll view; OCR list stays 140 pt.

## Progress Made
- Core 100 tests pass (3 new).

## Key Decisions
- Top-aligned stage: on a landscape iPad the 16:9 video leaves ~230 pt below it for chrome, so bars normally
  cover nothing; only tall debug panels overlap the bottom of the video.

## Current Limitations
- With debug panels on in landscape, the chrome covers the lower part of the video.

## Artifacts Produced
- None

## What Comes Next
- 7.8.0 QOL features.

## Summary
The video's size is fixed; everything else floats over the space below it.
