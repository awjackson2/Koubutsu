# Phase 7.0.0 Plan — Umbrella: Video mode (local video playback with OCR/translation)

## Phase
- **Number:** 7.0.0
- **Name:** Umbrella: Video mode (local video playback with OCR/translation)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
The user wants to load their own gameplay recordings (e.g. 10 minutes of Persona 3 Reload, Japanese) into the app from local storage and use them as a first-class video mode: controllable playback with OCR and translation running, plus a transcript. Footage stays outside the repository and the app bundle.

## Immediate Goal
1. Roadmap: 7.1.0 playback control → 7.2.0 Video mode UI → 7.3.0 transcript + subtitle export → 7.3.1 real-footage test (Persona 3 Reload; blocked until the file is downloadable).

## Confirmed Starting Point
`TestVideoSource` plays a file in a loop with no transport control; import via Files already copies into Documents (`MediaLibrary.importVideo`).

## Scope For This Phase
### In
- Pause/resume/seek/loop for file sources
- transport bar, library, import
- timestamped JP/EN transcript, SRT/CSV export
- real-footage OCR report once accessible
### Out
- Committing third-party gameplay footage (copyright; >100 MB)
- Frame-accurate stepping (future)

## Recommended Implementation Direction
Playback control is a separate protocol (`PlaybackControlling`) that only file sources adopt, so live capture code is untouched and downstream stays source-agnostic. Seeking is a content discontinuity: stabilizer and displayed translations reset.

## Technical Plan
Roadmap checklist (rewritten in Phase 7.5.0 — product direction: wherever Japanese text is on screen,
replace it with English in real time; Video mode behaves exactly like game mode):
```
- [x] 7.1.0 — PlaybackControlling + TestVideoSource play/pause/seek/loop/status
- [x] 7.2.0 — Video mode transport bar (play/pause, ±10 s, scrubber, loop, import)
- [x] 7.3.0 — transcript + export                     (superseded; removed in 7.5.0)
- [x] 7.3.1 — whole-video analysis, footage report     (superseded; removed in 7.5.0)
- [x] 7.4.0–7.4.2 — speaker labels, HUD suppression   (superseded; removed in 7.5.0)
- [x] 7.4.1 — paused frame keeps being read (kept)
- [x] 7.5.0 — reframe: remove analysis/transcript/speaker/HUD layers
- [x] 7.6.0 — replace-in-place overlay as default + instant updates
```

## Test Plan
Core: transcript/SRT/time-format tests on Linux. App: TestVideoSource pause/seek/status on the simulator. Screenshots of the transport bar and transcript.

## Key Decisions
- Footage is imported at runtime into the app's Documents; never bundled or committed.

## Expected Limitations At End Of Phase
- 7.3.1 blocked on Drive access.

## What Comes Next
- 7.1.0.

## Summary
Local gameplay videos become a controllable Video mode with OCR, translation and an exportable transcript.
