# Phase 4.0.0 Plan — Umbrella: performance, benchmark, physical device

## Phase
- **Number:** 4.0.0
- **Name:** Umbrella: performance, benchmark, physical device
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestones 10–11 and §33–34: measure and protect latency, make OCR quality regression-testable, and prepare physical iPad runs.

## Immediate Goal
1. Roadmap: 4.1.0 performance instrumentation → 4.2.0 deterministic OCR benchmark → 4.3.0 physical iPad procedure (external prerequisite).

## Confirmed Starting Point
Pipeline metrics from Majors 1–2.

## Scope For This Phase
### In
- Instrumentation, benchmark, device test procedure
### Out
- Metal renderer (only if measurements demand it)

## Recommended Implementation Direction
Measure first. Display path stays AVSampleBufferDisplayLayer unless numbers show otherwise.

## Technical Plan
Roadmap checklist:
```
- [x] 4.1.0 — CPU/memory/thermal/display-drop monitor + signposts        deps: 2.5.0  risk: low
- [x] 4.2.0 — OCR benchmark scoring (core) + CI benchmark on the clip       deps: 1.5.1  risk: med
- [x] 4.3.0 — Physical iPad test procedure + in-app benchmark trigger       deps: 4.2.0  risk: external
```

## Test Plan
Core scoring tests; CI benchmark test with minimum thresholds.

## Key Decisions
- Benchmark thresholds are regression floors, not targets.

## Expected Limitations At End Of Phase
- Physical-device numbers require the user's iPad (Mac + Xcode for install).

## What Comes Next
- 4.1.0.

## Summary
Performance becomes visible and OCR quality becomes regression-tested.
