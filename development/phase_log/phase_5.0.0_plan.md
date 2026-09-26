# Phase 5.0.0 Plan — Umbrella: UVC capture

## Phase
- **Number:** 5.0.0
- **Name:** Umbrella: UVC capture
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 12 and §29: replace the test source with a real USB capture device without downstream changes.

## Immediate Goal
1. Roadmap: 5.1.0 format selection (core) → 5.2.0 UVCVideoSource → 5.3.0 device monitor, source picker, hot-plug lifecycle.

## Confirmed Starting Point
`VideoSource` abstraction; `UVCVideoSource` placeholder (1.3.0).

## Scope For This Phase
### In
- Discovery, format selection, capture, hot-plug
### Out
- Switch 2 handshake validation (hardware)

## Recommended Implementation Direction
Everything device-independent (format choice) lives in core and is tested; AVFoundation code is thin.

## Technical Plan
Roadmap checklist:
```
- [x] 5.1.0 — CaptureFormatSelector (1080p60, YUV preference)          deps: 1.2.0  risk: low
- [x] 5.2.0 — UVCVideoSource on AVCaptureSession                        deps: 5.1.0  risk: HIGH (unverifiable without hardware)
- [x] 5.3.0 — CaptureDeviceMonitor, source picker, auto-switch, reconnect  deps: 5.2.0  risk: med
```

## Test Plan
Core selector tests; simulator tests for no-device behaviour.

## Key Decisions
- No capture permission prompt unless a device is present.

## Expected Limitations At End Of Phase
- Real device behaviour unverified until hardware arrives (§35).

## What Comes Next
- 5.1.0.

## Summary
USB capture becomes just another VideoSource.
