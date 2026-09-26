# Phase 6.0.0 Plan — Umbrella: UAC audio

## Phase
- **Number:** 6.0.0
- **Name:** Umbrella: UAC audio
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 13: play the capture device's audio through the iPad, low latency, on the shared host clock.

## Immediate Goal
1. Roadmap: 6.1.0 CaptureAudioService (USB input route → AVAudioEngine passthrough, volume, level meter, route-change handling).

## Confirmed Starting Point
Capture source (Major 5); settings model.

## Scope For This Phase
### In
- Passthrough, volume, meter
### Out
- Recording, speech recognition, spoken-dialogue translation (future; tap already exposes host-timed buffers)

## Recommended Implementation Direction
On iPadOS a UAC device is an audio route input (`.usbAudio`), not an AVCaptureDevice; select it as preferred input and route input→mixer.

## Technical Plan
Roadmap checklist:
```
- [ ] 6.1.0 — CaptureAudioService + settings + debug meter   deps: 5.3.0  risk: HIGH (hardware)
```

## Test Plan
Simulator: no USB input → `.unavailable`, no crash.

## Key Decisions
- 5 ms IO buffer for low latency.

## Expected Limitations At End Of Phase
- A/V sync unmeasured without hardware.

## What Comes Next
- 6.1.0.

## Summary
Game audio plays alongside captured video.
