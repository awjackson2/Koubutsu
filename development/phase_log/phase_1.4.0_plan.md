# Phase 1.4.0 Plan — Frame Tap and Diagnostics

## Phase
- **Number:** 1.4.0
- **Name:** Frame tap + diagnostics panel
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 3: expose real `CVPixelBuffer` frames with timestamps to processing consumers without touching the
display path, and make frame flow visible in a debug panel.

## Immediate Goal
1. `SampledFrameTap` — per-consumer `FrameSampler` + `LatestValueMailbox<VideoFrame>`; called from `FramePipeline.handle` after display enqueue; records sampled/dropped metrics.
2. `FramePipeline` supports one OCR tap (set/replace at runtime) with configurable rate.
3. `DebugPanel` — source kind, resolution, nominal FPS, pixel format, received/displayed/sampled FPS, last frame sequence / PTS / host time, frame age, tap drops.

## Confirmed Starting Point
- 1.3.0: `FramePipeline.handle` enqueues to `SampleBufferRenderer` and records received/displayed metrics.

## Scope For This Phase
### In
- Tap, panel, tests of tap behavior (app tests using synthetic frames).
### Out
- OCR consumer (1.5.0).

## Recommended Implementation Direction
Tap work on the delivery queue: one mutex-protected sampler check and at most one mailbox offer. The mailbox
retains at most one frame, so a stalled consumer holds one pixel buffer, never a growing pool.

## Technical Plan
`App/Pipeline/SampledFrameTap.swift`, `App/Pipeline/FramePipeline.swift`, `App/UI/DebugPanel.swift`, `App/UI/RootView.swift`, `AppTests/FrameTapTests.swift`.

## Test Plan
- App tests: tap at 5 FPS over a synthetic 60 FPS sequence of pixel-buffer frames samples every 12th frame; an unconsumed tap reports drops and holds one frame; consumer receives the newest frame.

## Key Decisions
- The tap lives in the app layer because it carries `VideoFrame`; its logic is the core `FrameSampler` + mailbox already tested on Linux.

## Expected Limitations At End Of Phase
- Frames are sampled but nothing consumes them until 1.5.0.

## What Comes Next
- 1.5.0 Vision OCR.

## Summary
Sampled, backpressured frame access for processing plus a live diagnostics panel.
