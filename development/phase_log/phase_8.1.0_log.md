# Phase 8.1.0 Log — Freeze & select

## Phase
- **Number:** 8.1.0
- **Name:** Study view: freeze the frame, tap or drag to select Japanese on the original image
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Stop on any frame and point at Japanese text on the original image.

## Major Additions
- Core: `OCRConfiguration.characterBoxes` / `.study`, `RecognizedTextObservation.characterBoxes`,
  `CharacterLayout` (recognizer boxes or width-weighted proportional fallback), `StudySelection`
  (tap → nearest character with slop, rect → per-line spans with ≥50% overlap), `SelectedSpan`.
- `TranslationCoordinator.translate(text:)` / `TranslationController.translate(text:)` (cached one-off).
- App: `FramePipeline.latestFrame`; `StudySession` (freeze → CGImage, accurate OCR, selection, translation);
  `StudyView` (frozen image, cyan outlines, yellow highlight, dashed drag rectangle, 2.5× loupe);
  `StudyPanel`; study button + S key; file sources pause and resume.
- `VisionOCRService.characterBoxes` via `RecognizedText.boundingBox(for:)`.
- CI screenshot series `study` (`--study-after`, `--study-select`).

## Major Changes
- Chrome shows the study panel instead of the bars while studying (also in full screen).

## Progress Made
- Core tests pass; CI green on d8e6bdf (iOS build + tests, IPA). App test
  `studyConfigurationReturnsCharacterBoxes` (8.2.0 commit) confirms per-character boxes on real OCR.

## Key Decisions
- The live pipeline keeps running under the frozen image (display path untouched); only file sources pause.

## Current Limitations
- Horizontal text only.

## Artifacts Produced
- None

## What Comes Next
- 8.2.0 dictionary data.

## Summary
Freeze the game, point at Japanese, see exactly what was selected and its translation.
