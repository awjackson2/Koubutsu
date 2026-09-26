# Phase 7.6.2 Log — Text stability from live webcam footage

## Phase
- **Number:** 7.6.2
- **Name:** Text stability: Japanese-only blocks, list items, confirmed replacements
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
🔧 Fix (Patch on 7.6.0): stop the overlay churn seen on a live C920 webcam recording of a Japanese manual.

## Major Additions
- `TextNormalizer.containsJapaneseText`, `TextNormalizer.listMarker` (`ListMarker.numbered(n, strict:)`, `.bullet`).
- `StabilizerConfiguration`: `requiresJapanese`, `shortTextMinimumConfidence` (0.5), `replacementObservations` (2),
  `coverFraction` (0.5), `minimumMissedResults` (2). `TrackedBlock.shownKey`, `missedResults`.
- `TextBlockGrouper`: `shortTailLength` (2), `shortTailMinimumHeightRatio` (0.5), `startsListItem`.
- `WebcamManualTests`: fixture of measured geometry/readings from the recording.

## Major Changes
- List-item lines start their own block; a loose `8.3.5mm` counts as item 8 only after item 7.
- Same-row fragments of different heights are not joined (Thai junk no longer glues onto item 3).
- Replacing shown text, or covering it with a new block, needs two readings; free-space text and growth stay instant.
- Tracks survive one missed OCR result regardless of time.

## Progress Made
- Core 96 tests pass (13 new). On the fixture, the list yields 8 blocks (item 1 includes its 「ク」 tail), no junk,
  and 20 alternating results cause no further events (before: regrouping and re-translation every result).

## Key Decisions
- Rules are generic (script, list syntax, glyph size, reading count), consistent with 7.5.0's no-per-game-heuristics.
- Overlap for "new block over shown block" is measured as covered fraction of the new block, computed against
  tracks shown before the current result, so touching neighbour lines in one result stay instant.

## Current Limitations
- Replacing shown text costs one more OCR interval (≈100 ms at 10 fps; ≈500 ms at the 2 fps the webcam run achieved).
- Overlay box layout and debug-panel height unchanged (7.6.3).

## Artifacts Produced
- None

## What Comes Next
- 7.6.3: overlay layout and fixed-height recognized-text panel.

## Summary
Only Japanese is replaced, list items stay separate, and shown English changes only on confirmed text.
