# Phase 1.5.0 Log — Vision Japanese OCR + recognized-text panel

## Phase
- **Number:** 1.5.0
- **Name:** Vision Japanese OCR + recognized-text panel
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Run Apple Vision Japanese recognition on sampled frames off the main actor and show text, confidence, boxes and latency.

## Major Additions
- `App/OCR/VisionOCRService.swift` — Swift `RecognizeTextRequest` (ja, accurate/fast, language correction, ROI), conversion to top-left `NormalizedRect`/quad, ROI → full frame, candidates.
- `App/OCR/OCRWorker.swift` — detached consumer loop, one request in flight, metrics, os.Logger output, signposts (4.1.0).
- `App/UI/RecognizedTextPanel.swift`; debug rows for OCR FPS, latency, capture→OCR.

## Major Changes
- Typed do-catch made explicit (`do throws(OCRError)`) after CI compile errors.

## Progress Made
- CI: `japaneseIsSupported`, `blankFrameYieldsNoObservations`, `workerProcessesNewestFrameAndStopsWhenTapCloses` pass.

## Key Decisions
- Swift Vision API (iOS 18+) rather than VNRecognizeTextRequest.

## Current Limitations
- Simulator Vision is CPU-only: first request ~2 min when competing with other work; device numbers pending (docs/device_testing.md).

## Artifacts Produced
- App/OCR/*
- App/UI/RecognizedTextPanel.swift
- AppTests/VisionOCRServiceTests.swift

## What Comes Next
- 1.5.1 fixture tests.

## Summary
Real Vision Japanese OCR runs on sampled frames and its results are visible.
