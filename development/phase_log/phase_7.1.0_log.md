# Phase 7.1.0 Log — Playback control for file sources

## Phase
- **Number:** 7.1.0
- **Name:** Playback control for file sources
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Give file sources pause, seek, skip and looping so a line can be read and checked; live capture keeps none of this.

## Major Additions
- Core `PlaybackStatus`, `PlaybackControlling`, `MediaTimeFormat` (Playback.swift) with tests
- `TestVideoSource` play/pause/seek/loop/status; `AppModel.playback` polled at 4 Hz, `togglePlayPause`, `seek(to:)`, `skip(by:)`, `setLooping`

## Major Changes
- Seeking resets the stabilizer, displayed translations and latest OCR

## Progress Made
- CI green on 9450363

## Key Decisions
- Downstream code still never learns the source type; only the transport UI queries `PlaybackControlling`

## Current Limitations
- None

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Media/Playback.swift
- App/Video/TestVideoSource.swift
- App/AppModel.swift

## What Comes Next
- See Major 7 umbrella ([phase_7.0.0_plan.md](phase_7.0.0_plan.md)).

## Summary
Pause, seek, skip and loop control for file sources.
