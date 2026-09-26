# Phase 5.1.0 Plan — Capture format selection

## Phase
- **Number:** 5.1.0
- **Name:** Capture format selection
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Pick 1080p60 (or the best alternative) from any UVC device's format list, device-independently.

## Immediate Goal
1. `CaptureFormatSelector`: prefer target frame rate, then exact/closest resolution (smaller over larger), then 4:2:0 bi-planar, then higher max FPS; 59.94 counts as 60.

## Confirmed Starting Point
Core `PixelSize`.

## Scope For This Phase
### In
- Selector + tests
### Out
- HDR / 4K / 120 Hz

## Recommended Implementation Direction
Frame rate beats resolution: smooth gameplay first; 720p text is still OCR-able.

## Technical Plan
`Sources/KoubutsuCore/Capture/CaptureFormatSelector.swift`.

## Test Plan
`CaptureFormatSelectorTests`.

## Key Decisions
- MJPEG accepted as last resort.

## Expected Limitations At End Of Phase
- Heuristic ordering until real devices are profiled.

## What Comes Next
- 5.2.0.

## Summary
Deterministic, tested capture format choice.
