# Phase 4.2.0 Plan — Deterministic OCR benchmark

## Phase
- **Number:** 4.2.0
- **Name:** Deterministic OCR benchmark
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
§33: repeatable OCR quality/latency measurement with expected checkpoints.

## Immediate Goal
1. Core `OCRBenchmark.evaluate` → exact-match rate, character accuracy, detection latency per expectation, missed text, mean OCR time.
2. CI benchmark test: decode the synthetic clip at 5 FPS, run Vision OCR, score against the manifest, print the report, enforce floors.

## Confirmed Starting Point
Clip + manifest (1.3.0), fixture tests (1.5.1), normalizer accuracy (2.1.0).

## Scope For This Phase
### In
- Scoring + CI benchmark test
### Out
- Real gameplay benchmark (needs user footage)

## Recommended Implementation Direction
Containment on normalized keys counts a recognized line that includes decorations as exact.

## Technical Plan
`Sources/KoubutsuCore/Benchmark/OCRBenchmark.swift`, `AppTests/OCRBenchmarkTests.swift`.

## Test Plan
Core scoring test; CI benchmark (exact-match ≥ 0.8, char accuracy ≥ 0.9).

## Key Decisions
- Benchmark runs offline (decode + OCR) so results do not depend on simulator playback timing.

## Expected Limitations At End Of Phase
- Synthetic text is cleaner than game footage.

## What Comes Next
- 4.3.0 physical device.

## Summary
OCR quality is measured and guarded in CI.
