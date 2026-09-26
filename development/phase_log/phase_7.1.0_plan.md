# Phase 7.1.0 Plan — Playback control for file sources

## Phase
- **Number:** 7.1.0
- **Name:** Playback control for file sources
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Reading and checking translations needs pause, seek and skip, which live capture cannot and should not offer.

## Immediate Goal
1. Core `PlaybackStatus` and `PlaybackControlling` protocol.
2. `TestVideoSource` conforms: play, pause, seek (exact), skip, looping toggle, status (time, duration, playing).
3. `AppModel` exposes playback status (4 Hz) and commands; seeking resets stabilizer, displayed translations and latest OCR.

## Confirmed Starting Point
`TestVideoSource` (AVPlayer + video output pull thread).

## Scope For This Phase
### In
- Protocol + conformance + model wiring
### Out
- UI (7.2.0)

## Recommended Implementation Direction
While paused no new frames arrive, so OCR idles and the last translations remain readable.

## Technical Plan
`Sources/KoubutsuCore/Media/Playback.swift`, `App/Video/TestVideoSource.swift`, `App/AppModel.swift`.

## Test Plan
App tests: pause stops frame delivery; seek to 12 s yields frames with presentation time ≈ 12 s; status duration ≈ 24 s. Core: time formatting.

## Key Decisions
- Separate protocol instead of widening `VideoSource`.

## Expected Limitations At End Of Phase
- None

## What Comes Next
- 7.2.0.

## Summary
File sources can be paused, scrubbed and skipped.
