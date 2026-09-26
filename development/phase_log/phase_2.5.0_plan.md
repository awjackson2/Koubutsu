# Phase 2.5.0 Plan — Translation panel end to end

## Phase
- **Number:** 2.5.0
- **Name:** Translation panel end to end
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Version-0 UI: live JP/EN under the video with latency and cache diagnostics (product plan §13, §38).

## Immediate Goal
1. `TranslationController` (@MainActor): OCR result → `TextStabilizer` → history + `TranslationCoordinator` → `displayed`.
2. `TranslationPanel`: JP and EN per stable block, translating/unavailable/failed states, download button.
3. Debug panel: provider, availability, translation latency, capture→EN, capture→shown, cache hits/misses/hit rate, duplicate detections.
4. Metrics: duplicate text detections and capture→shown latency (`PipelineMetrics.translationDisplayed`).

## Confirmed Starting Point
2.4.0 service; 1.5.0 OCR worker delivering `OCRResult` on the main actor.

## Scope For This Phase
### In
- Controller, panel, debug rows, app tests with a table translator
### Out
- Spatial overlay (Major 3)

## Recommended Implementation Direction
Stabilization is cheap and runs inline on the main actor per OCR result (~5 Hz). Translations run as child tasks; results are applied only if the block still shows the same text.

## Technical Plan
`App/Translation/TranslationController.swift`, `App/UI/TranslationPanel.swift`, `App/UI/DebugPanel.swift`, `App/AppModel.swift`, core `PipelineMetrics` additions.

## Test Plan
`AppTests/TranslationControllerTests.swift`: stable text translated once + cached, duplicates counted; typewriter translates only the final text; needs-download state; Apple availability smoke.

## Key Decisions
- Unavailable translation leaves the JP visible with an explicit state rather than hiding text.

## Expected Limitations At End Of Phase
- In-memory cache only.

## What Comes Next
- 2.6.0 settings UI.

## Summary
Japanese text now flows to English on screen with measured latency and cache behaviour.
