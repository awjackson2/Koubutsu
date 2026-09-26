# Phase 2.1.0 Plan — Text Normalization and Similarity

## Phase
- **Number:** 2.1.0
- **Name:** Japanese text normalization + similarity
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Every later comparison (change detection, stabilization, cache keys, benchmark accuracy) needs one canonical
notion of "the same text". Define it once, in core.

## Immediate Goal
1. `TextNormalizer.display` — compatibility normalization (width folding), whitespace collapsing that keeps spaces only between non-Japanese words.
2. `TextNormalizer.key` — comparison key without whitespace and without UI decoration glyphs (▶ ▼ ◆, arrows, stars).
3. `editDistance`, `similarity`, `isGrowth` (typewriter prefix growth with OCR-error tolerance), `characterAccuracy`.

## Confirmed Starting Point
- Core from Major 1; OCR returns raw Vision strings.

## Scope For This Phase
### In
- `Sources/KoubutsuCore/Text/TextNormalizer.swift` + tests.
### Out
- Kana/kanji reading normalization, furigana (learning mode, future).

## Recommended Implementation Direction
Foundation's `precomposedStringWithCompatibilityMapping` (NFKC) folds half-width katakana, full-width ASCII and
`…`→`...`; it is available in swift-corelibs-foundation, so behaviour is identical on Linux and iOS.

## Technical Plan
Pure functions on `String`/`Character`; edit distance over grapheme clusters (two-row DP).

## Test Plan
`TextNormalizerTests` (width folding, decorations, distance, growth, accuracy).

## Key Decisions
- Decorations are removed only from the key, never from displayed/translated text.

## Expected Limitations At End Of Phase
- O(n·m) edit distance; fine for on-screen text lengths.

## What Comes Next
- 2.1.1 line → block grouping.

## Summary
One canonical definition of Japanese text equality and similarity for the whole pipeline.
