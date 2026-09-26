# Phase 1.2.0 Log — Core Pipeline Contracts

## Phase
- **Number:** 1.2.0
- **Name:** Core pipeline contracts (Linux-tested)
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Define the platform-agnostic contracts for timing, sources, sampling, backpressure, metrics, OCR results and
settings in `KoubutsuCore`, fully unit-tested on Linux.

## Major Additions
- `Media/MediaTime.swift` — rational `MediaTime`, `HostTime`, `HostClock`, `ContinuousHostClock`.
- `Media/FrameTiming.swift` — `PixelSize`, `FrameTiming` (sequence, PTS, host time, source session), `TimedFrame`.
- `Media/VideoSource.swift` — `VideoSource<Frame>` protocol (synchronous frame handler, event handler, typed-throwing `start`), `VideoSourceKind/State/Error/Event`, `VideoFormat`.
- `Pipeline/FrameSampler.swift` — host-time sampler with phase keeping, jitter tolerance, resync on clock jumps.
- `Pipeline/LatestValueMailbox.swift` — capacity-1 async mailbox with drop accounting, cancellation, close.
- `Metrics/RateCounter.swift`, `Metrics/LatencyStats.swift`, `Metrics/PipelineMetrics.swift` — thread-safe collector + snapshot covering every metric listed in the product spec (received/displayed/sampled/OCR FPS, dropped OCR frames, OCR/translation latency, capture→result latency, cache hits/misses, duplicates).
- `Geometry/NormalizedRect.swift` — top-left-origin `NormalizedRect/Point/Quad`, Vision flip, IoU, ROI denormalization.
- `OCR/RecognizedTextObservation.swift`, `OCR/OCRService.swift` — observation model (text, confidence, box, quad, candidates, frame timing), `OCRResult`, `OCRConfiguration`, `OCRService<Frame>`.
- `Settings/AppSettings.swift` — growable, missing-key-tolerant settings.
- 27 tests in 7 suites.
- `development/design/architecture.md` — living architecture doc.

## Major Changes
- None versus plan. Swift Testing `#expect` cannot wrap mutating calls; tests use small helpers.

## Progress Made
- `swift test`: 27 passed (Linux, Swift 6.3.1).

## Key Decisions
- Frame delivery is a synchronous handler (no `AsyncStream` hop on the display path).
- Sampling keys on host time; presentation time restarts on loops.
- `Synchronization.Mutex`/`Atomic` for thread safety (Linux + iOS 18+).

## Current Limitations
- Contracts are not yet exercised by Apple adapters (1.3.0+).

## Artifacts Produced
- `Packages/KoubutsuCore/Sources/KoubutsuCore/**`, `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/**`, `development/design/architecture.md`.

## What Comes Next
- 1.3.0 TestVideoSource and display renderer.

## Summary
The platform-agnostic backbone exists and is tested: timing, sources, sampling, latest-frame backpressure, metrics, OCR model and settings.
