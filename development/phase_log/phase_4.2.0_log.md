# Phase 4.2.0 Log — Deterministic OCR benchmark

## Phase
- **Number:** 4.2.0
- **Name:** Deterministic OCR benchmark
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Regression-tested OCR quality on the synthetic clip.

## Major Additions
- `OCRBenchmark` scoring (core)
- `BenchmarkRunner` (app)
- `AppTests/OCRBenchmarkTests.swift` (0.5 FPS, thresholds exact ≥ 0.8, char accuracy ≥ 0.9)

## Major Changes
- None

## Progress Made
- CI runs 13–15: benchmark passes (≈70 s on the simulator).

## Key Decisions
- None

## Current Limitations
- Report text is printed but not captured in CI logs; thresholds only.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Benchmark/OCRBenchmark.swift
- App/Performance/BenchmarkRunner.swift

## What Comes Next
- 4.3.0.

## Summary
OCR quality is guarded in CI.
