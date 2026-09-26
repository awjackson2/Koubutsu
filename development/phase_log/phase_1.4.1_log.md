# Phase 1.4.1 Log — Stack-overflow crash on the frame delivery path

## Phase
- **Number:** 1.4.1
- **Name:** Stack-overflow crash on the frame delivery path
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Fix the app dying after 20–150 s in the simulator (screenshot runs 13–14).

## Major Additions
- `App/Video/FrameReleaser.swift` — displaced frames released on a utility queue.
- `App/Video/PullThread.swift` — dedicated user-interactive pull thread, 8 MB stack.

## Major Changes
- `TestVideoSource` timer replaced by `PullThread` (serialized via `pullQueue.sync`).
- `SampledFrameTap.offer` hands displaced frames to `FrameReleaser`.

## Progress Made
- Crash reports (collected by the screenshot job) showed EXC_BAD_ACCESS in the stack guard on `koubutsu.video.test.pull`: freeing a pooled CVPixelBuffer triggered a synchronous IOSurface XPC at the bottom of a deep unoptimized thunk chain.
- CI run 15: app running at every capture 20–270 s; no crash reports.

## Key Decisions
- No pixel-buffer deallocation on the delivery path, ever.

## Current Limitations
- None

## Artifacts Produced
- App/Video/FrameReleaser.swift
- App/Video/PullThread.swift
- docs/screenshots/ci15_*.jpg

## What Comes Next
- —

## Summary
The delivery path no longer frees pixel buffers, and the crash is gone.
