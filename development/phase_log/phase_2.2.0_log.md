# Phase 2.2.0 Log — Block tracking + temporal stabilization

## Phase
- **Number:** 2.2.0
- **Name:** Block tracking + temporal stabilization
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Emit text once it is stable; suppress typewriter partials and OCR flicker; count duplicates.

## Major Additions
- `TextStabilizer`, `StableText`, `TextEvent`, `TrackedBlock`, `StabilizerConfiguration`

## Major Changes
- None

## Progress Made
- `TextStabilizerTests` (8) pass; app test `typewriterTranslatesFinalTextOnly` confirms one translation for a 6-step reveal.

## Key Decisions
- Default window: 0.15 s and 2 observations (≈200 ms after completion at 5 FPS OCR).

## Current Limitations
- Greedy matching.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Text/TextStabilizer.swift

## What Comes Next
- 2.3.0.

## Summary
OCR noise becomes a small stream of stable-text events.
