# Phase 2.1.1 Plan — Line to Block Grouping

## Phase
- **Number:** 2.1.1
- **Name:** OCR line → text block grouping
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Vision returns lines. A two-line dialogue box must be translated as one sentence, while menu items must stay
separate. Group lines into blocks before stabilization and translation.

## Immediate Goal
1. `TextBlock` (lines, joined display text, key, union box, min confidence, frame).
2. `TextBlockGrouper` with resolution-independent thresholds (gap, height ratio, alignment/overlap as multiples of line height).

## Confirmed Starting Point
- 2.1.0 normalizer.

## Scope For This Phase
### In
- Horizontal text grouping + tests using the synthetic clip's real geometry.
### Out
- Vertical (top-to-bottom) Japanese text grouping — Vision iOS 26 reports `textDirection`; handled when seen in real footage.

## Recommended Implementation Direction
Sort lines top→bottom; a line joins the most recent block whose last line is directly above it (gap ≤ 0.8 × line
height, similar height, left-aligned or overlapping). Dialogue lines in the clip have gap ≈ 0.56 h; menu items ≈ 1.14 h.

## Technical Plan
`Sources/KoubutsuCore/Text/TextBlockGrouper.swift`, `NormalizedRect.isApproximatelyEqual`.

## Test Plan
`TextBlockGrouperTests`.

## Key Decisions
- Thresholds are configurable properties so real-game tuning needs no code change.

## Expected Limitations At End Of Phase
- Menus with tight spacing may merge; tuning comes with real footage.

## What Comes Next
- 2.2.0 stabilizer.

## Summary
Lines that belong to one dialogue box become one block of text.
