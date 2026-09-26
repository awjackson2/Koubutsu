# Phase 2.2.1 Log — Invalidate stale translations

## Phase
- **Number:** 2.2.1
- **Name:** Invalidate stale translations
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Remove a block's translation as soon as its stable text changes.

## Major Additions
- `TextEvent.invalidated(trackID:)`

## Major Changes
- None

## Progress Made
- Core test asserts invalidation on page change; `TranslationController` removes invalidated items.

## Key Decisions
- None

## Current Limitations
- Overlays still lag scene changes by OCR latency (≈1.5 s simulator; device expected far lower).

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Text/TextStabilizer.swift
- App/Translation/TranslationController.swift

## What Comes Next
- —

## Summary
Changed text never keeps showing its old translation.
