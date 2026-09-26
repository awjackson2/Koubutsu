# Phase 4.1.0 Log — Performance instrumentation

## Phase
- **Number:** 4.1.0
- **Name:** Performance instrumentation
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
CPU, memory, thermal, display drops, signposts in the debug panel.

## Major Additions
- `PerformanceMonitor`
- `SampleBufferRenderer.performanceMetrics()`
- `Signposts` around OCR

## Major Changes
- None

## Progress Made
- Simulator readings in screenshots: shown 60 FPS, display dropped 0/6443, CPU ~165 % (CPU-only Vision), memory ~110 MB.

## Key Decisions
- None

## Current Limitations
- Simulator values not representative of iPad hardware.

## Artifacts Produced
- App/Performance/PerformanceMonitor.swift

## What Comes Next
- 4.1.1.

## Summary
The device cost of the pipeline is visible.
