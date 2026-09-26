# Phase 7.8.0 Log — Quality-of-life: full screen, quick toggles, recent lines

## Phase
- **Number:** 7.8.0
- **Name:** Quality-of-life features
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Full screen, one-tap English/Japanese switching, peek, recent lines, keep-awake, text size, keyboard shortcuts.

## Major Additions
- Full screen (control-bar button, F): hides bars, panels and the status bar; tap the video to reveal controls,
  auto-hidden after 4 s. `--full-screen` launch option for CI.
- English/Japanese button (T) toggling `showTranslation`; press-and-hold on the video (0.25 s) shows the original
  with an "Original" label.
- View menu: English overlay, Japanese text list, Japanese in panel, OCR boxes, debug statistics.
- `RecentLinesView` (H): session lines newest first, copy one/all, clear (in-memory `DialogueHistory`).
- `KeyboardShortcuts`: invisible, always-present buttons for F, T, H, Space, ←/→, ⌘, (work in full screen).
- Settings: `showRecognizedText`, `keepScreenAwake` (idle timer off while running), `overlayTextScale` 80–150%
  (`OverlayLayout(textScale:)`), shortcuts help section.

## Major Changes
- `showDebugStatistics` defaults to false; the Japanese list is its own setting (default off). `--show-debug`
  turns both on.
- CI screenshots add a `fullscreen` series.

## Progress Made
- Core 102 tests pass; CI green on 14d7a2b (Core Linux, iOS build + tests, IPA, screenshots).
- Screenshots: the stage is at the same place in panel/debug, overlay and full-screen captures; full screen shows
  no bars or status bar; replacement boxes as before.

## Key Decisions
- Recent lines reuse the in-memory history; no export or persistence (7.5.0 removed transcripts).
- Keyboard shortcuts are invisible buttons rather than focus-based key handlers so they work with bars hidden.

## Current Limitations
- Tap vs hold feel and the auto-hide timing are unverified on a device.
- On the simulator OCR runs at ~0.5 results/s, so captures still show scene-change lag (not representative of device).

## Artifacts Produced
- docs/screenshots/qol780_fullscreen.jpg, docs/screenshots/qol780_overlay_controls.jpg

## What Comes Next
- On-device check with the webcam: full screen, peek, 7.6.2 stability.

## Summary
Full screen, instant English/Japanese switching, peek, recent lines, keep-awake, text size and keyboard control.
