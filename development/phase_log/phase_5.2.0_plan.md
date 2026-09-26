# Phase 5.2.0 Plan — UVCVideoSource

## Phase
- **Number:** 5.2.0
- **Name:** UVCVideoSource
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Receive live frames from an external UVC device into the existing pipeline.

## Immediate Goal
1. Discovery via `AVCaptureDevice.DiscoverySession(deviceTypes: [.external])`.
2. `AVCaptureSession` (.inputPriority), selected format + frame duration, `AVCaptureVideoDataOutput` 420v, `alwaysDiscardsLateVideoFrames`.
3. Host-clock timestamps from capture PTS; frames marked display-immediately; dropped-frame count.
4. Errors: no device, permission denied, configuration failure, runtime error, disconnection.

## Confirmed Starting Point
5.1.0 selector; `VideoFrame(sampleBuffer:timing:)` (1.3.0).

## Scope For This Phase
### In
- Capture source
### Out
- Audio (Major 6)

## Recommended Implementation Direction
Session work on a serial session queue; sample delegate on a user-interactive queue feeding `FramePipeline` directly.

## Technical Plan
`App/Video/UVCVideoSource.swift`.

## Test Plan
Simulator: discovery empty; unknown device ID → `.noDeviceAvailable` without a permission prompt.

## Key Decisions
- Device lookup precedes the permission request.

## Expected Limitations At End Of Phase
- Unverified on hardware.

## What Comes Next
- 5.3.0.

## Summary
Live capture feeds the same pipeline as test video.
