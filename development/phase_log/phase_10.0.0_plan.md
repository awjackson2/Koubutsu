# Phase 10.0.0 Plan — iPhone mode (umbrella)

## Phase
- **Number:** 10.0.0
- **Name:** iPhone mode — compact portrait and landscape layouts
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
Koubutsu is laid out for an iPad (a 1180 pt wide window). On an iPhone buttons are clipped off screen or too small
to hit, and the chrome covers the video. Make every feature usable on an iPhone in both portrait and landscape,
without changing the iPad layout.

## Immediate Goal
Ship 10.1.0–10.6.0 below.

## Confirmed Starting Point
Major 9 complete (`5f01abf`). Findings from the code:
- `TARGETED_DEVICE_FAMILY` is `2` (iPad only) for the app and tests; only iPad orientations are declared. The app
  reaches an iPhone only by sideloading with the device restriction removed.
- `ControlBar` is one `HStack` of about 11 controls plus the OSD status readout; it needs roughly 900 pt and
  overflows a 375–430 pt iPhone width, clipping the controls at the ends.
- Chrome is bottom-anchored over the window and overlays the stage. The panels have fixed heights (translation 150,
  Japanese list 140, study panel 210), so in iPhone landscape (about 390 pt tall) they cover the whole video.
- `VideoStageLayout.windowedInsets` handles only the top safe area. The Dynamic Island or notch on the side in
  landscape and the home indicator are not handled; the root view ignores the top safe area.
- `KIconButtonStyle` pads a 24 pt icon by 8×6 pt: hit areas are about 40×36 pt, below the 44 pt minimum. Icon-only
  buttons have no accessibility labels (0 `accessibilityLabel` in `App/`).
- The monitor housing (header, rails, caption) is sized for iPad and takes space the phone does not have.
- `KMenu` has `minWidth: 280`; the word bank rows have 110 pt thumbnails. These are tight but likely workable.
- Fonts already scale with Dynamic Type (`K.osd(_:relativeTo:)`) except the `*Fixed` variants used in the housing.
- CI builds, tests and captures screenshots on iPad simulators only.

## Definition of done
On the smallest supported iPhone width (375 pt) and on a Pro Max, in portrait and landscape:
- every control is reachable, has a hit area of at least 44×44 pt, and has a VoiceOver label;
- outside full screen, no chrome covers the video;
- study mode, the word card, the word bank, review, recent lines and settings are fully usable;
- the iPad layout is unchanged (iPad CI screenshots match before and after);
- CI builds and tests on an iPhone simulator as well as an iPad simulator.

## Scope For This Phase
### In
- iPhone device family and orientations; iPhone simulator in CI and in the on-demand screenshot workflow.
- A layout class chosen from the window size (not the device), so a narrow iPad window (Split View, Stage Manager)
  gets the compact layout too.
- Compact control and transport bars, a portrait layout, a landscape layout, study mode on compact layouts, and an
  accessibility pass over the sheets.
### Out
- New features or new video sources on iPhone. USB capture on iPhone is unverified (see Risks); if the SDK or a
  device shows it is iPad-only, the iPhone offers video files only and says why.
- A redesign of the iPad layout.

## Technical Plan
Roadmap checklist:
```
- [ ] 10.1.0 — iPhone target + layout classes: device family 1,2 and iPhone orientations; a LayoutClass in
               KoubutsuCore (regular / compact portrait / compact landscape) chosen from window size, with stage
               insets for all four safe-area edges (Linux tests); CI builds and tests on an iPhone simulator;
               screenshot workflow gets a `device` input; baseline iPhone screenshots of the current breakage.
               iPad layout unchanged.                                         deps: none          risk: med
- [ ] 10.2.0 — Compact control and transport bars: primary controls always visible (source, play/stop,
               EN/furigana/JP, study, full screen); words, recent lines, view options and settings move into
               one overflow menu; OSD status shortens to dot + state; transport bar drops the ruler and keeps
               skip, play, scrubber and time. 44 pt hit areas and VoiceOver labels on every bar control,
               iPad included.                                                 deps: 10.1.0        risk: low
- [ ] 10.3.0 — Compact portrait layout: video pinned to the top at full width in a slim housing (header only;
               no rails or maker's plate); bars and panels stacked below the video, never over it; panels take
               the remaining height instead of fixed 150/140 pt.              deps: 10.2.0        risk: med
- [ ] 10.4.0 — Compact landscape layout: video fills the height, positioned clear of the Dynamic Island or notch
               and the home indicator; bars become an overlay revealed by a tap and hidden automatically (like
               full screen today) or a side rail in the spare width, whichever the 10.1.0 baseline
               screenshots favour; panels open as an overlay.                 deps: 10.2.0        risk: high
- [ ] 10.5.0 — Study mode on compact layouts: study panel below the video in portrait and beside it or as a
               sheet in landscape; the word card and furigana fit; drag selection still works on a smaller
               video.                                                         deps: 10.3.0, 10.4.0 risk: med
- [ ] 10.6.0 — Sheets and accessibility pass: settings, word bank, review, recent lines and the word card on
               compact widths; Dynamic Type up to the accessibility sizes in the sheets; VoiceOver order and
               labels outside the bars; 44 pt targets throughout.            deps: 10.2.0        risk: low
```
Minors 10.7 to 10.9 are left free for follow-ups found in on-device testing (for example thermals and battery
during long play on iPhone, or a Picture in Picture view). These are candidates, not commitments.

## Test Plan
- Linux: `swift test` for LayoutClass selection and the stage/insets geometry at iPhone sizes (375×667,
  393×852, 440×956, both orientations) and at iPad sizes (unchanged results).
- CI: iOS build and tests on both an iPad and an iPhone simulator on every push.
- On-demand screenshots with `device=iphone` for each Minor, portrait and landscape; `device=ipad` at 10.2.0 and
  at the end to confirm the iPad is unchanged.
- On-device check on the user's iPhone at the end of 10.3.0, 10.4.0 and 10.5.0.

## Key Decisions
- Layout follows the window size, not `userInterfaceIdiom`: one code path, and narrow iPad windows benefit too.
- Geometry stays in KoubutsuCore's `VideoStageLayout` (rule 6); the UI only picks which layout to use.
- Engineering rule 1 is unaffected: layout changes never touch the display or OCR paths.
- Landscape (10.4.0) is the riskiest Minor, so it follows the lower-risk bar work and uses the baseline screenshots to
  choose between an overlay and a side rail. If it slips, 10.3.0 ships a usable portrait mode on its own.

## Risks
- **USB capture on iPhone:** `AVCaptureDevice.DeviceType.external` is documented for iPad
  (`platform_apis.md`). Whether an iPhone discovers UVC devices is unverified. 10.1.0 checks the SDK
  availability; the user's device settles it.
- Gesture conflicts in landscape between the tap that reveals the bars, the long press that shows the original
  Japanese, study drag selection and the system edge gestures.
- Small-video OCR overlay legibility: the overlay text scale may need a compact default.

## Expected Limitations At End Of Phase
- iPhone verification is by simulator screenshots plus the user's device; no automated UI tests.

## What Comes Next
- 10.1.0.

## Summary
Koubutsu works on an iPhone held either way, with every control reachable, and the iPad layout stays as it is.
