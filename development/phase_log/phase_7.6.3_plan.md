# Phase 7.6.3 Plan — Overlay layout that never covers neighbours; steady debug panel

## Phase
- **Number:** 7.6.3
- **Name:** Replacement boxes widen into free space before shrinking unreadably; fixed-height OCR panel
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
🔧 Fix (Patch on 7.6.0), second half of the webcam-footage clean-up (7.6.2 fixed the text side). In the
recording, English longer than its Japanese grew boxes downward and pushed them onto other items, clipping text
("operation decisio"); and the debug OCR panel below the video changed height with every result, resizing the
video and moving every box.

## Immediate Goal
1. English that does not fit at a readable size (≥ 60% of nominal) first widens its box rightward into free space
   (up to the next Japanese block on the same rows, or the video edge).
2. Only then shrinks to the minimum font, then grows downward, and only into free space; a box never covers
   another block's Japanese or an earlier box.
3. The recognized-text debug panel has a fixed height and scrolls; the video size no longer depends on OCR output.

## Confirmed Starting Point
7.6.2 (`0195720`). `OverlayLayout.place` in `Packages/KoubutsuCore/Sources/KoubutsuCore/Overlay/OverlayLayout.swift`;
`App/UI/RootView.swift`, `App/UI/RecognizedTextPanel.swift`.

## Scope For This Phase
### In
- `OverlayLayout`: `readableFontFraction`, obstacle-aware widen/grow; push-down stacking removed.
- `RecognizedTextPanel` in a fixed-height `ScrollView`.
### Out
- OCR throughput; blur rejection; background colour matching.

## Technical Plan
- Obstacles per item: other items' padded source frames and already placed frames.
- Fit order: base box at nominal→readable; widened box at nominal→readable; widened box at nominal→minimum;
  widened box grown down to the free space below (line limit from the fitted count; the renderer's
  `minimumScaleFactor` absorbs estimate error).

## Test Plan
Core `swift test` (layout tests rewritten for widen-first and no-cover); CI app build.

## Expected Limitations At End Of Phase
- Two boxes may still overlap by their 4 pt padding when their Japanese lines touch (both opaque; later draws on top).

## What Comes Next
- Re-record webcam footage on the iPad to confirm.

## Summary
English boxes use free space instead of covering neighbours, and the video no longer jumps.
