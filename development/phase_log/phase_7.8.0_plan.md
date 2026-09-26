# Phase 7.8.0 Plan — Quality-of-life: full screen, quick toggles, recent lines

## Phase
- **Number:** 7.8.0
- **Name:** Quality-of-life features
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Make the app pleasant to use while playing: full screen, one-tap toggles for the English/Japanese views, a way to
glance at the original, a list of recent lines, the screen staying awake, adjustable box text, and keyboard
shortcuts for an iPad keyboard.

## Immediate Goal
1. **Full screen**: button (and ⌘F / F) hides every bar, panel and the status bar; tapping the video shows the
   controls, which auto-hide after 4 s. The video stage does not move or resize (7.6.4).
2. **English on/off**: control-bar button (T) toggles the replacement overlay (shows the original Japanese).
3. **Peek**: press and hold on the video to see the original Japanese while held.
4. **View menu** with toggles: English overlay, Japanese text list (new `showRecognizedText`), original Japanese in
   the panel, OCR boxes, debug statistics.
5. **Recent lines** sheet (H): latest lines with their English, newest first; copy one or all; clear.
6. **Keep screen awake** while a source is running (setting, default on).
7. **Text size** of replacement boxes (setting, 80–150%).
8. **Keyboard**: space play/pause, ←/→ ±10 s (Video mode), F full screen, T English, H recent lines, ⌘, settings.
9. Debug statistics and the Japanese list default to off (`--show-debug` turns both on for CI).

## Confirmed Starting Point
7.6.4 (`1133912`). `App/UI/RootView.swift` (ControlBar), `App/UI/SettingsView.swift`,
`Packages/KoubutsuCore/Sources/KoubutsuCore/Settings/AppSettings.swift`, `DialogueHistory`.

## Scope For This Phase
### In
- `AppSettings`: `showRecognizedText`, `keepScreenAwake`, `overlayTextScale` (clamped 0.8…1.5);
  `showDebugStatistics` default false.
- `OverlayLayout` scaled by `overlayTextScale` (`VideoOverlayView.textScale`).
- `RootView`: full-screen state, tap/hold gestures on the stage, View menu, recent-lines sheet, keyboard shortcuts,
  idle-timer control.
- `RecentLinesView` (new).
### Out
- Export files, transcripts, analysis (removed in 7.5.0; not reintroduced).
- Picture-in-picture, external display output.

## Technical Plan
- Chrome visibility: `isFullScreen` + `chromeVisible`; chrome shown when `!isFullScreen || chromeVisible`; an
  auto-hide task restarts on each reveal. `.statusBarHidden(isFullScreen)`.
- Peek: `onLongPressGesture(minimumDuration: 0.25, …, onPressingChanged:)` sets `peeking` after the delay; the
  overlay is hidden while `peeking`. Tap toggles chrome in full screen.
- Idle timer: `UIApplication.shared.isIdleTimerDisabled = keepScreenAwake && isRunning`, updated on change.
- Keyboard: `.keyboardShortcut` on the control-bar buttons plus hidden buttons for space/arrows.

## Test Plan
Core `swift test` (settings defaults, decoding, clamping; layout scale); CI app build/tests; simulator screenshots.

## Key Decisions
- Recent lines reuse the in-memory `DialogueHistory` (already kept for translation context); nothing is saved.

## Expected Limitations At End Of Phase
- Gesture feel (hold delay, tap vs hold) unverified on device until the user tries it.

## What Comes Next
- On-device check of full screen and peek.

## Summary
Full screen, instant English/Japanese switching, peek, recent lines, keep-awake, text size and keyboard control.
