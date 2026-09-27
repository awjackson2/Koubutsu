# Phase 10.2.0 Log — Compact control and transport bars

## Phase
- **Number:** 10.2.0
- **Name:** Compact control and transport bars; 44 pt targets and VoiceOver labels
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
See `phase_10.2.0_plan.md` (umbrella `phase_10.0.0_plan.md`). Make the control and transport bars fit a 375 pt
iPhone when the layout class is compact, and give every bar control a 44 pt hit area and a VoiceOver label on
iPhone and iPad alike.

## Major Additions
- `ControlBar` compact arrangement (`layoutClass.isCompact`): source menu, play/stop, EN/furigana/JP cycle, Study,
  Full screen and a "More" `KMenu`. Icons only in compact portrait; compact landscape keeps the source and overlay
  titles. No logo in compact. About 356 pt wide at 375 pt.
- "More" menu: Words (with "N due" in the title), Recent lines, the five view toggles of the eye menu, Loop video
  (file sources only) and Settings. Icon: pixel `chevron` rotated 90° to point down; a 6 pt red block on it when
  words are due. Sheets open 300 ms after the item is chosen so the popover has closed first.
- `OSDStatus(compact:)`: dot and state label only when compact; one VoiceOver element "Status" with a spoken state.
- `VideoTransportBar` compact: no ruler ticks, no duration, loop or import; smaller time counter.
- `Scrubber`: `showsTicks`; VoiceOver element "Position", value "m:ss of m:ss", adjustable in 10 s steps through
  `model.skip(by:)` (`accessibilityAdjustableAction`).
- `KIconButtonStyle.minimumTarget` (44) and a `.frame(minWidth:minHeight:)` + `contentShape` after the pressed
  background: the hit area grows, the visible pressed block does not.

## Major Changes
- Accessibility labels on every icon-only bar control, iPad included: Source (value: source name), Play/Stop,
  Overlay (value English/Furigana/Original Japanese, with a hint), View options, Study, Words (N due), Recent lines,
  Full screen/Exit full screen, Settings, More; transport Back 10 seconds, Play/Pause, Forward 10 seconds, Loop
  (On/Off), Import video. Logo and time counters hidden from VoiceOver.
- `KIconLabel` hides its pixel icon from VoiceOver (the asset name `px.play` was otherwise read out).
- Transport icons now go through `KIconLabel` (same rendering as the bare `PixelIcon`).
- Bar vertical padding reduced (control bar 6 → 2 pt, transport 4 → 0 pt; scrubber 32 → 44 pt tall) so the 44 pt
  targets leave both bars at their previous heights. On the iPad the only visible change is a few points of extra
  horizontal spacing between icon buttons.
- The regular `ControlBar` keeps the same controls in the same order; it is now built from shared helpers
  (`sourceMenu`, `playStopButton`, `overlayButton`, `studyButton`, `fullScreenButton`).

## Progress Made
- Immediate goals 1–5 of the plan implemented.

## Key Decisions
- Overflow icon is the existing `chevron` glyph turned down; adding a new pixel glyph needs `Tools/pixel_art.py` and
  the asset catalog, out of scope.
- Loop goes to the More menu in compact; import stays in the source menu.
- VoiceOver scrubbing uses the same 10 s step as the skip buttons rather than seeking by fractions.
- Accessibility strings passed as `String` values (not ternaries of literals) to avoid overload ambiguity between the
  `LocalizedStringKey` and `StringProtocol` variants.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge. The dev container has no Xcode and, this session, no Swift
  toolchain either, so no `swift test` run (no KoubutsuCore change in this phase).
- Depends on `LayoutClass` and `EnvironmentValues.layoutClass` from 10.1.0; builds only once 10.1.0 is merged.
- The 300 ms sheet delay after a More item is a guard against a popover/sheet presentation clash, not observed on
  device yet.
- Chrome still overlays the video on iPhone until 10.3.0 / 10.4.0. No iPhone or iPad screenshots taken yet.

## Artifacts Produced
- `App/UI/RootView.swift` (`ControlBar`, `OSDStatus`), `App/UI/VideoTransportBar.swift`,
  `App/Theme/Components.swift` (`KIconButtonStyle`, `KIconLabel`), `development/phase_log/phase_10.2.0_plan.md`,
  `development/phase_log/phase_10.2.0_log.md`.

## What Comes Next
- CI build and on-demand screenshots (`device=iphone` portrait and landscape, `device=ipad` for the unchanged bars).
- 10.3.0 compact portrait layout, 10.4.0 compact landscape layout.

## Summary
Both bars have a compact arrangement that fits a 375 pt iPhone with secondary controls in one More menu, and every bar
control on iPhone and iPad has a 44 pt hit area and a VoiceOver label, with the iPad bar otherwise as before.
