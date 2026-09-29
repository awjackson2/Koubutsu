# Phase 5.4.0 Plan — Device camera as a video source

## Phase
- **Number:** 5.4.0
- **Name:** Device camera as a video source
- **Status:** Planned
- **Date drafted:** 2026-09-29

## Purpose
Let the user point the iPhone/iPad's own back camera at a TV, monitor or a handheld Switch and read/translate the
game text, with no capture hardware. Numbered under Major 5 (video sources): it is a third source beside the
bundled/imported video and the USB capture device.

## Immediate Goal
1. The source menu lists "Device camera"; selecting it shows the live back-camera feed on the stage and runs the
   same OCR → translation → overlay/study pipeline as every other source.
2. Frames stay on the device (rule 9); nothing downstream knows the source is a camera (rule 3).

## Confirmed Starting Point
- `App/Video/UVCVideoSource.swift`: `AVCaptureSession` source for `.external` devices; format chosen by
  KoubutsuCore `CaptureFormatSelector` (closest to 1080p60); hot-plug via `CaptureDeviceMonitor`.
- `AppModel.SourceSelection`: `.media(MediaItem)`, `.uvc(CaptureDeviceInfo?)`.
- `NSCameraUsageDescription` mentions only the USB capture device.

## Scope For This Phase
### In
- Generalise the capture source: `CaptureVideoSource(kind:)` with `.external(id)` (today's UVC behaviour,
  unchanged) and `.builtIn` (back wide-angle camera via `AVCaptureDevice.default(.builtInWideAngleCamera,
  for: .video, position: .back)`). `UVCVideoSource` becomes that type or a thin wrapper.
- Camera specifics:
  - Orientation: frames delivered horizon-level for the current device orientation using
    `AVCaptureDevice.RotationCoordinator` (iOS 17) on the output connection, so the picture is upright in portrait
    and landscape.
  - Format: `CaptureFormatSelector` targeting 1920×1080 at 60, falling back to 30 (a TV is 16:9; the stage
    aspect stays 16:9).
  - Continuous autofocus and auto exposure; no mirroring.
- `SourceSelection.camera`; source menu item "Device camera" (with its own icon); `keepScreenAwake` applies.
- Permission: updated `NSCameraUsageDescription` ("…reads video from the camera or an external USB capture
  device…"); denied permission shows the existing source error with a Settings hint.
- Stop the camera when the app goes to the background (existing scene-phase handling).
- KoubutsuCore tests for any new pure logic (e.g. rotation-angle to frame-orientation mapping, format fallback).
### Out
- Tap-to-focus / exposure lock, perspective correction of a screen seen at an angle, hand-shake stabilisation
  (candidates for 5.4.1+ after device testing).
- Front camera.

## Recommended Implementation Direction
Reuse the proven capture path (session queue, latest-frame output, host-clock timestamps) rather than a second
implementation; the only differences are device discovery, rotation and hot-plug (not applicable to the camera).

## Technical Plan
- `App/Video/CaptureVideoSource.swift` (from `UVCVideoSource.swift`), `App/AppModel.swift`, `App/UI/RootView.swift`
  (source menu), `Tools/gen_xcodeproj.py` + project (usage string), `development/design/platform_apis.md`
  (RotationCoordinator, built-in camera APIs as verified in the CI SDK report), architecture doc.

## Test Plan
Core tests on Linux; CI build + tests on iPad and iPhone simulators (the simulator has no camera: selecting it must
fail cleanly with "no camera", which a unit test can check). Real check: the user's iPhone pointed at a screen.

## Key Decisions
- Back wide-angle camera only — it is the one that focuses on a screen at arm's length.
- Rotation via RotationCoordinator, not ad hoc UI geometry (rule 6 keeps overlay mapping in the coordinate layer).

## Expected Limitations At End Of Phase
- Glare, moiré and a slanted view lower OCR accuracy; holding the phone steady (or a stand) matters.

## What Comes Next
- 5.4.1+: tap-to-focus/exposure lock, optional perspective correction, per-source OCR tuning.

## Summary
Any screen becomes a source: point the device camera at it and Koubutsu reads and translates the game text.
