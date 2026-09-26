# Phase 7.6.0 Plan — Replace-in-place overlay + instant updates

## Phase
- **Number:** 7.6.0
- **Name:** Replace-in-place overlay as the default display; instant-update stabilization
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Wherever Japanese text is on screen, cover it with its English in real time, in Video mode and game mode alike.

## Immediate Goal
1. Each Japanese block is covered by an opaque box of the same size (plus padding) holding the English, font shrunk to fit.
2. English appears on the first OCR hit (no multi-reading stability wait); text changes (typewriter, next line) update the English.
3. While a changed text translates, the previous English for that block stays visible instead of flashing the Japanese.
4. Late translations for text no longer on screen are dropped (existing `setStatus` rule); repeats come from the cache.
5. Defaults: OCR 10 samples/s, display mode overlay.

## Confirmed Starting Point
Phase 7.5.0 (9b18f8b).

## Scope For This Phase
### In
- `StabilizerConfiguration` defaults (0 s, 1 observation).
- `OverlayLayout` replace mode with a pure font-fitting function (core, Linux-tested).
- `VideoOverlayView` rendering; `TranslationController` carry-over of the previous English per track.
- `AppSettings` defaults.
### Out
- Background colour sampling from the video (opaque dark box for now).

## Technical Plan
- `OverlayLayout.place(_:mapper:textLength:)`: frame = source rect expanded by padding (minimum width), font = largest size ≤ nominal (70% of the Japanese line height) whose estimated wrapped text fits the frame; below the minimum font the frame grows downward. Overlap resolution kept for grown frames.
- `DisplayedText.previousTranslation`: set from the track's last English when its text changes; overlay/panel show `translation ?? previousTranslation`.
- `.invalidated` no longer removes the entry (an instant restabilization follows in the same result); `.removed` does.

## Test Plan
Core `swift test` (layout fitting, stabilizer instant emission, settings defaults); CI app build/tests; footage screenshots.

## Key Decisions
- Instant emission trades extra translation requests during typewriter reveals for zero wait; the coordinator's in-flight dedup and cache bound the cost, and stale results are discarded.

## Expected Limitations At End Of Phase
- Box background is a flat dark colour, not matched to the game UI.

## What Comes Next
- Logs for 7.1–7.6, design-doc sync, README screenshots.

## Summary
Japanese on screen is replaced by English, instantly, in place.
