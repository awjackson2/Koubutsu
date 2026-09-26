# Phase 1.5.0 Plan — Vision Japanese OCR

## Phase
- **Number:** 1.5.0
- **Name:** Vision Japanese OCR + recognized-text debug panel
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 4: run real Apple Vision Japanese text recognition on sampled frames, asynchronously, and show
text, confidence, bounding boxes and latency.

## Immediate Goal
1. `VisionOCRService: OCRService` using the Swift `RecognizeTextRequest` (iOS 18+ API verified in 1.1.1), `recognitionLanguages = [ja]`, accurate/fast, language correction, optional region of interest.
2. Conversion of Vision observations to `KoubutsuCore.RecognizedTextObservation` (top-left-origin box + quad, confidence, top-N candidates, frame timing).
3. `OCRWorker` — a detached consumer loop over `SampledFrameTap` (off main); records OCR start/finish/failure metrics; publishes `OCRResult` to the main actor.
4. Japanese support check at startup via `supportedRecognitionLanguages`; failures surface as UI errors, never crashes.
5. `RecognizedTextPanel` listing JP text, confidence, box; `DebugPanel` gains OCR latency, capture→OCR latency, OCR FPS, in-flight, failures; recognized text also logged via `os.Logger`.

## Confirmed Starting Point
- 1.4.0: `SampledFrameTap` installed in `FramePipeline`; `AppModel.processingTap` at `settings.ocrRate` (5 FPS).

## Scope For This Phase
### In
- Items above.
### Out
- Stabilization/dedup (Major 2), translation (Major 2), box drawing over video (Major 3).
- Fixture accuracy test (1.5.1).

## Recommended Implementation Direction
- One request in flight at a time (the worker awaits each recognition); the tap's mailbox guarantees the next request uses the newest frame.
- `Vision` and `KoubutsuCore` both define `NormalizedRect`/`RecognizedTextObservation`; the adapter file qualifies names explicitly.
- Region of interest is converted with `NormalizedRect.bottomLeftOrigin`; results are mapped back to full-frame coordinates with `denormalizing` (verified in 1.5.1).

## Technical Plan
`App/OCR/VisionOCRService.swift`, `App/OCR/OCRWorker.swift`, `App/AppModel.swift`, `App/UI/RecognizedTextPanel.swift`, `App/UI/DebugPanel.swift`, `App/UI/RootView.swift`, `Tools/sdk_report.sh` (Vision geometry blocks).

## Test Plan
- App tests: `VisionOCRService.supportedLanguages` includes Japanese; OCR worker processes frames from a tap and records metrics; worker stops when tap closes.

## Key Decisions
- Swift Vision API over `VNRecognizeTextRequest`: async/Sendable-friendly, iOS 26 additions (text direction) available.

## Expected Limitations At End Of Phase
- Every OCR result replaces the displayed list (no stabilization yet).

## What Comes Next
- 1.5.1 OCR fixture test; Major 2 umbrella.

## Summary
Real Vision Japanese OCR on sampled frames, never on the display path, visible in the debug UI with latency metrics.
