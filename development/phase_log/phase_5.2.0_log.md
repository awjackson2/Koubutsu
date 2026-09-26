# Phase 5.2.0 Log — UVCVideoSource

## Phase
- **Number:** 5.2.0
- **Name:** UVCVideoSource
- **Status:** Completed (unverified on hardware)
- **Date completed:** 2026-09-26

## Phase Goal
Live UVC frames into the existing pipeline.

## Major Additions
- `UVCVideoSource` on AVCaptureSession (.external discovery, selected format/frame duration, 420v, discard late frames, host-clock timing, disconnect/runtime error events)

## Major Changes
- None

## Progress Made
- CI: no devices in simulator; unknown device → `.noDeviceAvailable` without a permission prompt.

## Key Decisions
- None

## Current Limitations
- Not run against real capture hardware.

## Artifacts Produced
- App/Video/UVCVideoSource.swift
- AppTests/CaptureTests.swift

## What Comes Next
- 5.3.0.

## Summary
USB capture is implemented as just another VideoSource.
