# Phase 9.3.0 Plan — Animations

## Phase
- **Number:** 9.3.0
- **Name:** Smooth, cheap animations in the easy places
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Make the identity feel alive without distracting from the game (umbrella 9.0.0).

## Immediate Goal
1. Boot sequence (~1.5 s): logo mark resolves from coarse pixels to full detail, the wordmark types out with a
   block cursor, "SIGNAL OK" line, then a scanline wipe reveals the app. Tap skips.
2. Study freeze: a paper flash, then a red scan line sweeps the frozen frame while it is being read; the
   "▮▮ PAUSE" readout stamps in.
3. Selection: highlight brackets snap in from slightly larger.
4. Blinking block cursor on waiting/hint texts; study panel slides up; word bank due badge pulses.
5. Reduce Motion: boot becomes a short fade, sweeps and pulses are off.

## Confirmed Starting Point
9.2.0 (`96e9e33`).

## Scope For This Phase
### In
- `App/Theme/Animations.swift` (BootSequenceView, ScanSweep, BlinkingCursor, PixelResolve) and wiring.
### Out
- Animations on the live replacement boxes (would distract while playing).

## Test Plan
CI build/tests; screenshots (boot is over before the first capture at 20 s).

## Summary
Koubutsu powers on like a VCR and freezes like one.
