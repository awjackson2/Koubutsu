# Phase 7.6.3 Log — Overlay layout that never covers neighbours; steady debug panel

## Phase
- **Number:** 7.6.3
- **Name:** Replacement boxes widen into free space before shrinking unreadably; fixed-height OCR panel
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
🔧 Fix (Patch on 7.6.0): layout half of the webcam-footage clean-up.

## Major Additions
- `OverlayLayout.readableFontFraction` (0.6); `fit(…, floor:)`.

## Major Changes
- `OverlayLayout.place`: widen rightward into free space, then shrink to 9 pt, then grow downward into free space.
  Obstacles are other blocks' Japanese and earlier boxes. The push-below stacking (which moved boxes onto other
  text) is removed.
- `RootView`: `RecognizedTextPanel` in a 140 pt `ScrollView`.

## Progress Made
- Core 97 tests pass; layout tests `narrowBoxWidensIntoFreeSpaceBeforeShrinking`,
  `wideningStopsAtTheNextTextOnTheRow`, `grownBoxNeverCoversTheTextBelow` replace the grow/stack tests.

## Key Decisions
- Boxes may overlap a neighbour's 4 pt padding (touching lines) but not its text.

## Current Limitations
- In panel/both display modes the translation panel still changes height with its content.
- Not yet re-verified on device with the webcam.

## Artifacts Produced
- None

## What Comes Next
- Re-record the webcam test on the iPad with 7.6.2 + 7.6.3.

## Summary
English boxes use free space instead of covering neighbours, and the video no longer jumps.
