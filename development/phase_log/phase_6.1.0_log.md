# Phase 6.1.0 Log — CaptureAudioService

## Phase
- **Number:** 6.1.0
- **Name:** CaptureAudioService
- **Status:** Completed (unverified on hardware)
- **Date completed:** 2026-09-26

## Phase Goal
Play UAC audio through the iPad with low latency.

## Major Additions
- `CaptureAudioService` (USB route input → AVAudioEngine, volume, RMS meter, route-loss handling)
- settings + debug row

## Major Changes
- None

## Progress Made
- CI: `audioServiceReportsMissingUSBInput` passes (no USB input in simulator).

## Key Decisions
- None

## Current Limitations
- A/V sync and latency unmeasured without hardware.

## Artifacts Produced
- App/Audio/CaptureAudioService.swift

## What Comes Next
- Hardware validation (docs/device_testing.md §4–5).

## Summary
Captured game audio playback is implemented.
