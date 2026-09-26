# Phase 7.5.0 Plan — Reframe Video mode: remove offline analysis, transcripts, speaker and HUD heuristics

## Phase
- **Number:** 7.5.0
- **Name:** Reframe Video mode: remove offline analysis, transcripts, speaker and HUD heuristics
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Product direction clarified: wherever Japanese text is on screen, replace it with English in real time; Video mode must behave exactly like game (capture) mode. Phases 7.3.0–7.4.2 built offline analysis, transcripts, speaker extraction and HUD suppression, which do not serve that goal and add hand-tuned, single-game heuristics. This phase removes them and resets Major 7's roadmap.

## Immediate Goal
1. Remove core `TranscriptBuilder`, `HUDFilter`, speaker extraction (`TextBlock.speaker`, `StableText.speaker`) and their tests.
2. Remove app `VideoAnalyzer`, `TranscriptView`, transcript/HUD/analysis state in `TranslationController`/`AppModel`, footage analysis test, transcript/HUD settings and launch options.
3. Keep: transport bar (play/pause/seek/loop/import), paused-frame re-delivery, footage screenshot tooling.
4. A small label above a line (e.g. a name) stays its own block: tighten the grouping height ratio so it is replaced in place like any other text.
5. Footage workflow reduced to app screenshots on external footage.
6. Major 7 umbrella roadmap rewritten: 7.5.0 reframe, 7.6.0 replace-in-place + instant updates.

## Confirmed Starting Point
Branch head after Phase 7.4.2; footage runs 4–6 on Persona 3 Reload.

## Scope For This Phase
### In
- Deletions and simplifications listed above
- umbrella rewrite
### Out
- Replace-in-place rendering and instant stabilization (7.6.0)

## Recommended Implementation Direction
Shipped phase logs stay as history; this phase records the reversal.

## Technical Plan
Core: delete `Translation/Transcript.swift`, `Text/HUDFilter.swift`; simplify `TextBlockGrouper`, `TextStabilizer`, `AppSettings`. App: delete `Video/VideoAnalyzer.swift`, `UI/TranscriptView.swift`, `AppTests/FootageAnalysisTests.swift`; simplify `TranslationController`, `AppModel`, `VideoTransportBar`, `TranslationPanel`, `SettingsView`, `DemoTranslationService` (LaunchOptions), `Tools/ci_screenshots.sh`, `.github/workflows/footage.yml`.

## Test Plan
Core `swift test`; CI app tests; name-label-separate-block test with geometry measured on the Persona frame.

## Key Decisions
- Every Japanese text region is treated the same: no dialogue/HUD/speaker classification.

## Expected Limitations At End Of Phase
- None

## What Comes Next
- 7.6.0 replace-in-place overlay and instant updates.

## Summary
Video mode is back to being game mode on a file; heuristic analysis layers are gone.
