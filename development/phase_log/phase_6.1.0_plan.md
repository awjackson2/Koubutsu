# Phase 6.1.0 Plan — CaptureAudioService

## Phase
- **Number:** 6.1.0
- **Name:** CaptureAudioService
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Implement UAC audio passthrough and controls.

## Immediate Goal
1. `.playAndRecord` session, preferred input = USB audio, `AVAudioEngine` input→main mixer, volume, RMS level tap, stop on route loss.
2. Settings: play capture audio, volume; debug panel audio row.

## Confirmed Starting Point
6.0.0.

## Scope For This Phase
### In
- Service + wiring
### Out
- Recording/ASR

## Recommended Implementation Direction
Tap closure built in a nonisolated context (audio render thread).

## Technical Plan
`App/Audio/CaptureAudioService.swift`, `App/AppModel.swift`, settings/debug UI; core `AppSettings` fields.

## Test Plan
`AppTests/CaptureTests.swift` audio case; core settings decoding (volume clamp).

## Key Decisions
- Test video keeps using AVPlayer audio (`.playback`).

## Expected Limitations At End Of Phase
- Unverified on hardware.

## What Comes Next
- Hardware validation (§35).

## Summary
Captured game audio plays through the iPad.
