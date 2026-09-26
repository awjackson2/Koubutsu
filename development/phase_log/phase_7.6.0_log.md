# Phase 7.6.0 Log — Replace-in-place overlay + instant updates

## Phase
- **Number:** 7.6.0
- **Name:** Replace-in-place overlay as the default display; instant-update stabilization
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Wherever Japanese text is on screen, cover it with its English in real time, in Video mode and game mode alike.

## Major Additions
- `OverlayLayout.fit` / `wrappedLines` / `nominalFontSize`: largest font (≤ 70% of the Japanese line height) whose wrapped English fits the Japanese block's box; the box grows downward only below the minimum font.
- `DisplayedText.previousTranslation` / `visibleTranslation`: a block's previous English stays visible while its changed text translates.
- `PlaceholderTranslationService` (`--placeholder-translator`): labelled "[EN] …" stand-in of realistic length for simulator footage screenshots.

## Major Changes
- `StabilizerConfiguration` defaults: 0 s, 1 observation (emit on first reading); windowed behaviour kept as an explicit configuration in tests.
- `.invalidated` no longer removes the displayed entry; the same result restabilizes it.
- `DialogueHistory` merges a block's typewriter growth into one entry.
- `AppSettings` defaults: OCR 10 FPS, display mode overlay.
- `VideoOverlayView` renders fixed-size opaque boxes with `minimumScaleFactor` as a safety net.

## Progress Made
- Core: 83 tests pass (Linux CI green).
- iOS CI build-test green on the PR head (62e7f84), including the rewritten controller tests (first-reading English, update on change with carry-over).

## Key Decisions
- Instant emission accepts extra translation requests during typewriter reveals; the cache, in-flight dedup and stale-result dropping bound the cost.

## Current Limitations
- Box background is a flat dark colour.
- Real translation latency during typewriter reveals is unmeasured until run on an iPad with the ja→en model.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Overlay/OverlayLayout.swift
- App/UI/VideoOverlayView.swift, App/Translation/TranslationController.swift, App/Translation/DemoTranslationService.swift

## What Comes Next
- Footage screenshots of replace-in-place on the Persona 3 Reload video; device validation (docs/device_testing.md).

## Summary
Japanese on screen is replaced by English in place, on the first OCR reading, and follows text changes without flashing the original.
