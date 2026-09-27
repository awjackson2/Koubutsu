# Phase 9.3.0 Log — Animations

## Phase
- **Number:** 9.3.0
- **Name:** Smooth, cheap animations in the easy places
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_9.3.0_plan.md` (umbrella 9.0.0).

## Major Additions
- `App/Theme/Animations.swift`: `BootSequenceView` (logo resolves 4→8→16→32 px, wordmark types out, status line,
  scanline wipe; tap skips), `PixelResolve`, `BlinkingCursor`, `ScanSweep`, `FreezeFlash`, `kPulse`.
- `--skip-boot` launch option for screenshots.
- `development/design/ui_theme.md`; README cover art.

## Major Changes
- Study: freeze flash, red scan line while reading, selection brackets snap in (`K.snap`), study layer fades.
- Blinking cursors on waiting states; source error box scales in.

## Progress Made
- CI green on `024312b` (iOS build and tests including ThemeTests).

## Key Decisions
- No animation on the live replacement boxes (distracting while playing).
- Reduce Motion: sweeps and pulses off, boot shortened to a fade.

## Current Limitations
- Animation smoothness on device not yet measured; simulator screenshots only show still frames.

## Artifacts Produced
- `App/Theme/Animations.swift`, `App/UI/{RootView,StudyView,StudyPanel}.swift`, `development/design/ui_theme.md`.

## What Comes Next
- 9.4.0: monitor housing around the video (user request).

## Summary
The identity moves: VCR power-on, freeze scan, snapping brackets, blinking cursors.
