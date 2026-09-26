# Phase 2.2.0 Plan — Block Tracker and Stabilizer

## Phase
- **Number:** 2.2.0
- **Name:** Block tracking + temporal stabilization
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 5: stop re-emitting unchanged text, and avoid translating every partial string of a typewriter reveal.

## Immediate Goal
1. `TextStabilizer.process(OCRResult) -> [TextEvent]` — tracks blocks across results by IoU (or proximity + textual relation), maintains per-track current text, first-seen frame, observation count.
2. Emits `.stabilized(StableText)` once text is unchanged for ≥ `minimumStableDuration` and ≥ `minimumObservations`; `.removed` after `removeAfter` unseen.
3. OCR flicker absorbed (similarity ≥ `noiseSimilarity`); duplicate detections counted.

## Confirmed Starting Point
- 2.1.x normalizer and grouper.

## Scope For This Phase
### In
- Core stabilizer + tests (typewriter, flicker, page change, independent blocks, removal, confidence filter, multi-line).
### Out
- App wiring (2.5.0).

## Recommended Implementation Direction
Typewriter suppression falls out of the stability rule: while characters appear, text changes at every OCR
sample, so the window keeps resetting. Defaults: 0.15 s and 2 observations → at 5 FPS OCR, text is emitted on
its second identical sighting (~200 ms after it completes).

## Technical Plan
`Sources/KoubutsuCore/Text/TextStabilizer.swift`.

## Test Plan
`TextStabilizerTests`.

## Key Decisions
- `StableText.firstSeenFrame` = first frame showing the final text → capture→translation latency is measured from when the player could first read it.

## Expected Limitations At End Of Phase
- Greedy matching; adequate for the handful of blocks on a game screen.

## What Comes Next
- 2.3.0 translation contracts.

## Summary
Per-frame OCR becomes a small stream of "this text is now stable" events.
