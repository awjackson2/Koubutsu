# Phase 1.3.0 Log — TestVideoSource + shared display renderer + synthetic test clip

## Phase
- **Number:** 1.3.0
- **Name:** TestVideoSource + shared display renderer + synthetic test clip
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Play prerecorded Japanese video in a loop as a `VideoSource`, rendered through the same zero-copy `AVSampleBufferDisplayLayer` path live capture uses.

## Major Additions
- `App/Video/TestVideoSource.swift` — AVPlayer + `AVPlayerItemVideoOutput` pulled at 2× source rate on a user-interactive queue, host-time stamped frames, looping, AVPlayer audio.
- `App/Video/VideoFrame.swift` — `CMSampleBuffer`/`CVPixelBuffer` frame, `VideoFrameFactory` (cached format description, display-immediately attachment), 420v IOSurface attributes.
- `App/Video/SampleBufferRenderer.swift`, `App/UI/VideoDisplayView.swift` — single display path.
- `App/Pipeline/FramePipeline.swift` — fan-out point.
- `App/AppModel.swift` — composition root, lifecycle (scene phase), source selection, import.
- `App/Platform/MediaLibrary.swift` — bundled + imported videos.
- `Tools/make_test_clip.py` → `App/Resources/TestMedia/synthetic_ja_1080p60.{mp4,json}` (24 s, 1080p60 H.264 + AAC blips, 712 KB; title menu, typewriter dialogue over moving background, small status text, katakana menu).
- `App/Video/UVCVideoSource.swift` placeholder.

## Major Changes
- KVO status observation moved to a nonisolated helper (Swift 6 isolation safety).
- File sharing keys moved to `Config/Koubutsu-Info.plist` (fixed in 1.5.1 after CI showed `INFOPLIST_KEY_UIFileSharingEnabled` is not a generated key).

## Progress Made
- CI run 13: `deliversTimedFrames` (≥30 frames, contiguous sequence, increasing host time, 1920×1080, stops on stop()), `reportsFormat` (1920×1080, 60 FPS, 420v), `missingFileFails`, `bundledClipAndManifestArePresent`, `infoPlistEnablesFileSharing` pass.

## Key Decisions
- DisplayImmediately sample buffers — no timebase, no added buffering.

## Current Limitations
- Display cadence vs panel refresh not yet measured on device.

## Artifacts Produced
- App/Video/*
- App/Pipeline/FramePipeline.swift
- App/Platform/MediaLibrary.swift
- Tools/make_test_clip.py
- App/Resources/TestMedia/*

## What Comes Next
- 1.4.0 frame tap.

## Summary
Prerecorded video is a first-class, looping, zero-copy frame source on the live-capture display path.
