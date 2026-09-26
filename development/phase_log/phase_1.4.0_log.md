# Phase 1.4.0 Log — Frame tap + diagnostics panel

## Phase
- **Number:** 1.4.0
- **Name:** Frame tap + diagnostics panel
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Expose sampled `CVPixelBuffer` frames with timestamps to processing through a latest-frame mailbox, and show frame flow in a debug panel.

## Major Additions
- `App/Pipeline/SampledFrameTap.swift` — mutex-guarded `FrameSampler` + `LatestValueMailbox<VideoFrame>`, sampled/dropped metrics.
- `FramePipeline.setProcessingTap`.
- `App/UI/DebugPanel.swift` — source, format, in/shown/sampled FPS, last frame sequence/PTS/age, OCR drops.

## Major Changes
- CI found `self` used before init completion in `AppModel`; fixed by building from a local `AppSettings` (landed with the 1.5.0 commit).

## Progress Made
- CI: `factoryWrapsWithoutCopying`, `samplesAtTargetRateAndKeepsOnlyNewest` (120 frames @60 → 10 offered, 9 dropped, newest #108), `pipelineFeedsTapAfterDisplay` pass.

## Key Decisions
- One processing tap; the mailbox caps retained frames at one.

## Current Limitations
- None

## Artifacts Produced
- App/Pipeline/SampledFrameTap.swift
- App/UI/DebugPanel.swift
- AppTests/FrameTapTests.swift

## What Comes Next
- 1.5.0 OCR.

## Summary
Frames reach processing at a configurable rate without any queue, and the panel shows it.
