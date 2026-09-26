# Phase 2.1.1 Log — OCR line → text block grouping

## Phase
- **Number:** 2.1.1
- **Name:** OCR line → text block grouping
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Group lines of one dialogue box into a block; keep menu items separate.

## Major Additions
- `TextBlock`, `TextBlockGrouper` (height-relative gap/alignment thresholds)
- `NormalizedRect.isApproximatelyEqual`

## Major Changes
- None

## Progress Made
- `TextBlockGrouperTests` pass using the clip's real geometry (dialogue gap 0.56 h merges, menu gap 1.14 h separates).

## Key Decisions
- None

## Current Limitations
- Vertical Japanese text not yet grouped.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Text/TextBlockGrouper.swift

## What Comes Next
- 2.2.0.

## Summary
Two-line dialogue becomes one sentence.
