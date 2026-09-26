# Phase 1.5.1 Plan — OCR Fixture Tests

## Phase
- **Number:** 1.5.1
- **Name:** Vision OCR fixture tests on CI
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Prove on CI that real Vision Japanese OCR recognizes known text from real decoded frames, and that bounding
boxes and region-of-interest mapping land where the text actually is.

## Immediate Goal
1. Test helper that decodes a frame at a given time from the bundled synthetic clip (`AVAssetReader`, `420v`).
2. `ClipManifest` decoding of `synthetic_ja_1080p60.json`.
3. Tests: dialogue lines, title question and katakana menu recognized; box IoU with the manifest ≥ 0.5; same with the dialogue region of interest (validates ROI → full-frame mapping); text drawn with the system font into a pixel buffer is recognized.

## Confirmed Starting Point
- 1.5.0 `VisionOCRService`, bundled clip + manifest from 1.3.0.

## Scope For This Phase
### In
- Tests + test helpers only (plus `ClipManifest` in the app target for reuse by the Major 4 benchmark).
### Out
- Accuracy statistics / benchmark harness (Major 4).

## Recommended Implementation Direction
Compare text after removing whitespace; Vision may normalize full-width punctuation, so tests require the
core kanji/kana sequence rather than byte equality where punctuation is involved.

## Technical Plan
`App/Platform/ClipManifest.swift`, `AppTests/OCRFixtureTests.swift`, `AppTests/ClipFrameReader.swift`.

## Test Plan
The tests above on the iOS 26.5 simulator in CI.

## Key Decisions
- Fixture is the committed synthetic clip, so results are deterministic and copyright-free.

## Expected Limitations At End Of Phase
- Synthetic rendering is cleaner than real game footage; real-footage accuracy is measured in Major 4.

## What Comes Next
- Major 2 umbrella (stabilization, translation, cache).

## Summary
Lock in OCR correctness (text and geometry) with deterministic CI tests on decoded video frames.
