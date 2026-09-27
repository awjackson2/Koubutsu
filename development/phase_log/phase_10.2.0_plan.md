# Phase 10.2.0 Plan — Compact control and transport bars

## Phase
- **Number:** 10.2.0
- **Name:** Compact control and transport bars; 44 pt targets and VoiceOver labels
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
The control bar needs about 900 pt and the transport bar is built for an iPad width, so on a 375–430 pt iPhone the
controls are clipped off screen. Bar buttons are about 40×36 pt, below the 44 pt minimum, and no icon-only button
has a VoiceOver label. This phase makes both bars usable at 375 pt and makes every bar control reachable by touch and
VoiceOver, on the iPad as well.

## Immediate Goal
1. With `layoutClass.isCompact`, the control bar shows only source, play/stop, the EN/furigana/JP cycle, Study,
   Full screen and one "More" overflow menu (words with due count, recent lines, view toggles, loop, settings), and
   fits 375 pt with 44 pt targets.
2. `OSDStatus` in compact shows only the blinking dot and the state label.
3. The transport bar in compact drops the ruler ticks, the duration, loop and import; it keeps −10 s, play/pause,
   +10 s, the scrubber and the time counter.
4. `KIconButtonStyle` guarantees a 44×44 pt hit area; every icon-only bar control has an accessibility label; the
   scrubber is an adjustable VoiceOver element with a value.
5. The regular (iPad) layout keeps every control where it is today.

## Confirmed Starting Point
Major 9 complete (`5f01abf`); umbrella `phase_10.0.0_plan.md`.
- `App/UI/RootView.swift`: `ControlBar` is one `HStack` of logo, source `KMenu`, play/stop, overlay cycle, eye
  `KMenu` of view toggles, Study, Words (due tag), Recent lines, Full screen, Settings and `OSDStatus`
  (dot + state + size + FPS).
- `App/UI/VideoTransportBar.swift`: rewind, play/pause, forward, time, tick `Scrubber`, duration, loop, import.
- `App/Theme/Components.swift`: `KIconButtonStyle` pads by 8×6 pt (24 pt icon → 40×36 pt); `KIconLabel` shows the
  pixel icon, whose image would be read by VoiceOver as its asset name.
- Phase 10.1.0 (in parallel) provides `LayoutClass` in KoubutsuCore and `@Environment(\.layoutClass)` in the app.
- Pixel icons available (`Tools/pixel_art.py`): no "more"/ellipsis glyph exists; `chevron` does.

## Scope For This Phase
### In
- `ControlBar` and `OSDStatus` in `App/UI/RootView.swift`.
- `App/UI/VideoTransportBar.swift`.
- `KIconButtonStyle` and `KIconLabel` in `App/Theme/Components.swift`.
### Out
- `RootView.body` layout and geometry (10.3.0 / 10.4.0).
- Sheets: settings, word bank, review, recent lines, word card (10.6.0).
- `LayoutClass` and the environment key (10.1.0); Packages, Tools, CI, LaunchOptions.
- New pixel icons (would need `Tools/pixel_art.py` and the asset catalog).

## Recommended Implementation Direction
Read `@Environment(\.layoutClass)` in `ControlBar`, `OSDStatus` and `VideoTransportBar` and branch between a regular
and a compact arrangement built from shared button helpers, so the iPad arrangement stays literally the same list.
Put the 44 pt minimum in `KIconButtonStyle` as an outer frame applied after the pressed background, so the visible
pressed block keeps its current size and only the hit area grows; drop the bars' vertical padding by the same amount
so the bar heights do not change.

## Technical Plan
- `KIconButtonStyle`: `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())` after the background.
- `KIconLabel`: the pixel icon is `accessibilityHidden(true)`; the title (if any) is the label.
- `ControlBar`: helpers `sourceMenu`, `playStopButton`, `overlayButton`, `studyButton`, `fullScreenButton`;
  compact arrangement adds `moreMenu` (`KMenu`, pixel icon `chevron` turned 90° to point down, red dot when words are
  due) with items Words (N due), Recent lines, the view toggles, Loop video (when a file is playing) and Settings.
  Compact portrait: icons only; compact landscape: source and overlay keep a short title. Logo dropped in compact.
- Accessibility labels: Source, Play/Stop, Overlay (value English/Furigana/Japanese), View options, Study, Words
  (N due), Recent lines, Full screen/Exit full screen, Settings, More; logo hidden; status combined.
- `OSDStatus(compact:)`: state label only when compact.
- `VideoTransportBar`: icons through `KIconLabel`; labels Back 10 seconds, Play/Pause, Forward 10 seconds, Loop,
  Import video; compact drops duration, loop and import; `Scrubber(showsTicks:)`, accessibility label "Position",
  value "elapsed of duration", `accessibilityAdjustableAction` stepping ±10 s via `model.skip(by:)`.

## Test Plan
- No KoubutsuCore change, so no Linux tests for this phase; `swift test` still run to confirm the package is intact.
- macOS CI after merge: iOS build (iPad and iPhone simulators); on-demand screenshots `device=iphone` portrait and
  landscape, and `device=ipad` to confirm the iPad bars are unchanged.

## Key Decisions
- Overflow icon: `chevron` rotated to point down — no "more" glyph exists and adding one is out of scope.
- Hit area grows outside the visible pressed block — the iPad look stays the same; only spacing grows by a few points.
- Loop moves to the overflow menu in compact; import stays reachable from the source menu.
- VoiceOver adjusts the scrubber in 10 s steps, the same as the skip buttons.

## Expected Limitations At End Of Phase
- Not compiled locally (no Xcode); verified by macOS CI after merge.
- Chrome still overlays the video on iPhone until 10.3.0 / 10.4.0.

## What Comes Next
- 10.3.0 compact portrait layout, 10.4.0 compact landscape layout.

## Summary
Both bars get a compact arrangement that fits a 375 pt iPhone, with secondary controls in one overflow menu, and
every bar control gets a 44 pt hit area and a VoiceOver label on iPhone and iPad alike.
