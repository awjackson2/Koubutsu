# Phase 2.1.2 Log — Join same-line OCR fragments

## Phase
- **Number:** 2.1.2
- **Name:** Join same-line OCR fragments
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Stop small text split by Vision from being stabilized and translated piece by piece.

## Major Additions
- `TextBlockGrouper.mergeLineFragments` (row overlap ≥ 50 %, gap ≤ 1.2 line heights)

## Major Changes
- None

## Progress Made
- Core tests: fragments セ / ーブし / て / います… → 「セーブしています...」; distant same-row texts stay apart (74 tests pass).

## Key Decisions
- None

## Current Limitations
- Thresholds tuned on synthetic text.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Text/TextBlockGrouper.swift

## What Comes Next
- —

## Summary
Fragments of one line are translated as one line.
