# Phase 4.1.0 Plan — Performance instrumentation

## Phase
- **Number:** 4.1.0
- **Name:** Performance instrumentation
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 10: surface CPU, memory, thermal state, display drops, and Instruments signposts.

## Immediate Goal
1. `PerformanceMonitor`: process CPU % (mach thread info), physical footprint, thermal state, low-power mode.
2. Display drops from `AVSampleBufferVideoRenderer.videoPerformanceMetrics` (iOS 17.4).
3. `OSSignposter` intervals around OCR.
4. Debug panel rows.

## Confirmed Starting Point
Debug panel (1.4.0–2.5.0).

## Scope For This Phase
### In
- Monitor + UI rows + signposts
### Out
- GPU utilisation (not exposed by public API; use Instruments)

## Recommended Implementation Direction
Sampled at 1 Hz alongside the 4 Hz metrics poll to keep overhead negligible.

## Technical Plan
`App/Performance/PerformanceMonitor.swift`, `App/Video/SampleBufferRenderer.swift`, `App/OCR/OCRWorker.swift`, `App/UI/DebugPanel.swift`, `App/AppModel.swift`.

## Test Plan
CI compile; values are device-dependent.

## Key Decisions
- Signposts use the Points of Interest category for zero-config Instruments viewing.

## Expected Limitations At End Of Phase
- Simulator values are not representative.

## What Comes Next
- 4.2.0 benchmark.

## Summary
The debug panel shows the device cost of the pipeline.
