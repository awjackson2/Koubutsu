# Phase 7.6.2 Plan — Text stability from live webcam footage

## Phase
- **Number:** 7.6.2
- **Name:** Text stability: Japanese-only blocks, list items, confirmed replacements
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
🔧 Fix (Patch on 7.6.0). A 37 s screen recording of the app on a C920 webcam pointed at a Japanese instruction
manual (numbered list 1–8, Thai text on the facing page) showed a chaotic overlay:
- Thai misread as random Latin/digit strings every frame ("700705imau", "231570820447"), shown as boxes and
  joined sideways into the item-3 line ("231570820447 3. Play/Pause…").
- The numbered list regrouped into 1–4 blocks on consecutive OCR results; a one-glyph wrapped line 「ク」
  (confidence 0.30, 0.68× line height) became a "Ku" box or glued to item 2 ("C2. Volume knob…").
- Every regrouping re-translated (52 requests for an unchanging 8-line list) and redrew boxes.
- At 2 OCR results/s, the 0.6 s removal window dropped a track after one missed reading.

## Immediate Goal
1. Blocks with no kana/kanji are never tracked (no Latin/digit junk boxes).
2. A line starting a numbered/bulleted list item starts its own block; a short wrapped tail joins the line above.
3. Side-by-side fragments of clearly different heights are not joined into one line.
4. A shown translation is replaced by different (non-growth) text only after that text is read twice; a new block
   over an already shown block also needs two readings. Growth (typewriter) and blocks in empty space stay instant.
5. A track is removed only after it is missed in at least two OCR results (and the time window).
6. One-glyph blocks need confidence ≥ 0.5.

## Confirmed Starting Point
`12da0db`. `TextBlockGrouper`, `TextStabilizer`, `TextNormalizer` in `Packages/KoubutsuCore/Sources/KoubutsuCore/Text/`.

## Scope For This Phase
### In
- `TextNormalizer.containsJapaneseText`, `TextNormalizer.listMarker`.
- `TextBlockGrouper`: list-item breaks, short-tail height tolerance, fragment height check.
- `StabilizerConfiguration`: `requiresJapanese`, `replacementObservations`, `minimumMissedResults`,
  `shortTextMinimumConfidence`; `TrackedBlock.shownKey` / `missedResults`.
- Core tests, including a fixture from the webcam recording's measured geometry.
### Out
- Overlay box layout and debug-panel height (7.6.3).
- OCR throughput (2 fps achieved at 1080p accurate) and blur rejection.

## Recommended Implementation Direction
All rules are generic text-layout rules (script, list markers, glyph height), not per-game heuristics (7.5.0).
Confirmation applies only where something is already shown, so game dialogue appearing in an empty box stays instant.

## Technical Plan
- `listMarker(_:)`: `1.` `1．` `1)` `(1)` `①`… `・` (not `・・`) `●■◆※-`; a number followed by a digit
  (`8.3.5mm`) counts only when the block above began with the previous number.
- `belongs`: never join a list-item line; lines of ≤2 key characters accept height ratio ≥ 0.5.
- `continues`: fragment heights must be within `heightRatioRange`.
- Stabilizer emission: required readings = `minimumObservations` for a fresh track in free space or growth of the
  shown text, else `max(minimumObservations, replacementObservations)`.

## Test Plan
Core `swift test`; CI app tests (controller tests use growth and fresh tracks, expected unchanged).

## Expected Limitations At End Of Phase
- Replacing shown text costs one extra OCR interval (100 ms at 10 fps, ~500 ms at the 2 fps seen on the webcam).

## What Comes Next
- 7.6.3: overlay layout (widen before growing, no pushing onto neighbours), fixed-height recognized-text panel.

## Summary
Only Japanese is replaced, list items stay separate, and shown English changes only on confirmed text.
