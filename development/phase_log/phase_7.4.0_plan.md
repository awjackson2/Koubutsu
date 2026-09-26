# Phase 7.4.0 Plan — Speaker labels and HUD suppression (from Persona 3 Reload footage)

## Phase
- **Number:** 7.4.0
- **Name:** Speaker labels and HUD suppression (from Persona 3 Reload footage)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
The first real-footage run (footage workflow run 4: 600 samples, 586 with text, 1054 ms mean OCR on the simulator) produced 426 transcript entries for about 150 dialogue lines. Two causes: speaker name labels are merged into the dialogue text (「伊織順平おーす、久々じゃん。」), and static HUD text (button hints 「◎オート日早送り」 and its OCR variants, the date 「4/18土」, 「TALK」, time of day 「夜」) is stabilized repeatedly.

## Immediate Goal
1. Core: `TextBlock.speaker` — a short, smaller line directly above-left of a text block (merged or separate) becomes the block's speaker, not part of its text; `StableText.speaker`, transcript speaker column/prefix, `TranslationContext.speaker`.
2. Core: `HUDFilter` — text that re-stabilizes at the same place with similar content (≥3 times) is classified as HUD and suppressed from transcript, panel/overlay and translation; different text at that place (next dialogue line) is not.
3. Apply in `TranslationController` and `VideoAnalyzer`; setting `hideHUDText` (default on).
4. Re-run the footage workflow and compare.

## Confirmed Starting Point
Footage report (CSV, SRT) from footage workflow run 4; frame analysis: name label ≈0.6× text height, above-left of text.

## Scope For This Phase
### In
- Speaker extraction
- HUD filter
- wiring + setting
- before/after footage comparison
### Out
- Game-specific templates
- Choice-menu detection

## Recommended Implementation Direction
Both are generic heuristics (many games draw speaker labels above text and persistent HUD hints), tuned and tested with patterns copied from the real report.

## Technical Plan
`Sources/KoubutsuCore/Text/TextBlockGrouper.swift`, `Text/TextStabilizer.swift`, new `Text/HUDFilter.swift`, `Translation/Transcript.swift`, `Settings/AppSettings.swift`; app: `TranslationController`, `VideoAnalyzer`, `SettingsView`.

## Test Plan
Core: speaker split for merged and separate labels; no split for equal-height lines; HUD variants suppressed after 3 sightings; different dialogue at the dialogue box never suppressed; transcript speaker output. CI footage run: entries drop substantially with dialogue retained.

## Key Decisions
- Speaker text is excluded from the comparison key so name OCR noise does not re-trigger stabilization.

## Expected Limitations At End Of Phase
- Heuristic thresholds; per-game tuning may follow.

## What Comes Next
- 7.4.1 footage demo screenshots.

## Summary
Real-footage transcripts become dialogue-only, with speakers.
