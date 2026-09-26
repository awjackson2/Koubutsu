# Phase 2.5.0 Log — Translation panel end to end

## Phase
- **Number:** 2.5.0
- **Name:** Translation panel end to end
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
JP/EN panel fed by stabilizer → coordinator, with translation/caching diagnostics.

## Major Additions
- `TranslationController`, `TranslationPanel`, debug rows (translation latency, capture→EN, capture→shown, cache, duplicates)
- `PipelineMetrics.translationDisplayed`

## Major Changes
- None

## Progress Made
- CI: `stableTextIsTranslatedOnceAndCached` (1 call for 10 OCR results, 8 duplicates, history recorded), `typewriterTranslatesFinalTextOnly`, `notInstalledShowsDownloadState` pass.

## Key Decisions
- None

## Current Limitations
- None

## Artifacts Produced
- App/Translation/TranslationController.swift
- App/UI/TranslationPanel.swift
- AppTests/TranslationControllerTests.swift

## What Comes Next
- 2.6.0.

## Summary
Japanese on screen becomes English under the video.
