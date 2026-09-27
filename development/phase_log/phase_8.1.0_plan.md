# Phase 8.1.0 Plan — Freeze & select

## Phase
- **Number:** 8.1.0
- **Name:** Study view: freeze the frame, tap or drag to select Japanese on the original image
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
First step of study mode (umbrella 8.0.0): the learner can stop on any frame and point at text.

## Immediate Goal
1. A study button (book icon, S key) freezes the current frame on the stage; a file source pauses.
2. The frozen frame is re-read with accurate OCR and per-character boxes; Japanese lines get faint outlines.
3. Tap selects the character under the finger (and its line); drag selects every character inside the rectangle.
   A magnifier follows the finger.
4. A study panel shows the selected text large, its line, and the English translation of the selection.
5. Done (or S / Esc) returns to live; a file source resumes if it was playing.

## Confirmed Starting Point
`82e99cd` (umbrella). `FramePipeline`, `VisionOCRService`, `RootView` stage/chrome (7.6.4, 7.8.0).

## Scope For This Phase
### In
- Core: `OCRConfiguration.characterBoxes`, `RecognizedTextObservation.characterBoxes`, `CharacterLayout`
  (Vision boxes or width-weighted proportional fallback), `StudySelection` (tap → character, rect → spans).
- App: latest-frame hold in `FramePipeline`; `StudySession` (freeze, OCR, selection, translation);
  `StudyView` (frozen image, outlines, highlight, magnifier, gestures) and `StudyPanel`.
- `TranslationCoordinator.translate(text:)` for arbitrary text (cached).
### Out
- Dictionary lookup (8.2–8.4).

## Technical Plan
- Freeze copies the frame to a `CGImage` (CIContext) for display and runs `VisionOCRService` on the held frame
  with `characterBoxes: true`, accurate, full frame. The live pipeline keeps running underneath (display path
  unaffected); the frozen image is drawn on top of the stage.
- Per-character boxes: `RecognizedText.boundingBox(for:)` per grapheme (SDK report, iOS 18), converted once
  in `VisionOCRService`; any count mismatch falls back to proportional layout.
- Gesture: one `DragGesture(minimumDistance: 0)`; travel < 12 pt = tap.

## Test Plan
Core `swift test` (layout fallback, tap hit-testing, rect selection across lines); CI build/tests; screenshots.

## Expected Limitations At End Of Phase
- Horizontal text only; vertical Japanese selects by line.

## What Comes Next
- 8.2.0 dictionary data.

## Summary
Freeze the game, point at Japanese, see exactly what was selected and its translation.
