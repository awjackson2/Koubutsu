# Phase 4.3.0 Plan — Physical iPad procedure and in-app benchmark

## Phase
- **Number:** 4.3.0
- **Name:** Physical iPad procedure and in-app benchmark
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 11 and §34–36 cannot run in CI. Provide an exact procedure and an in-app benchmark trigger so on-device results can be collected by the user and logged.

## Immediate Goal
1. `docs/device_testing.md`: install, prerecorded run, benchmark, sustained run, capture-hardware checklist (§35), glass-to-glass latency (§36).
2. Debug panel **Run benchmark** action using `BenchmarkRunner`, report shown in the panel and logged.

## Confirmed Starting Point
4.1.0 monitor, 4.2.0 benchmark.

## Scope For This Phase
### In
- Doc + in-app trigger
### Out
- Executing the device tests (external prerequisite: user hardware)

## Recommended Implementation Direction
Every measurement in the doc maps to a debug-panel field, so results are read off the app, not guessed.

## Technical Plan
`docs/device_testing.md`, `App/AppModel.swift` (`runBenchmark`), `App/UI/DebugPanel.swift`.

## Test Plan
CI compile; the benchmark itself is covered by `OCRBenchmarkTests`.

## Key Decisions
- Status: implemented; the physical run is blocked on hardware and recorded as such.

## Expected Limitations At End Of Phase
- No physical-device numbers yet.

## What Comes Next
- Major 5.

## Summary
Everything needed to run and record physical-iPad and capture-hardware tests is in place.
