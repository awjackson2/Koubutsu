# Phase 1.2.0 Plan — Core Pipeline Contracts

## Phase
- **Number:** 1.2.0
- **Name:** Core pipeline contracts (Linux-tested)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Define the platform-agnostic types every later phase builds on, with deterministic tests that run in the
Linux container: timing, the video-source contract, OCR sampling, latest-frame backpressure, metrics,
the OCR observation model, and settings.

## Immediate Goal
1. `MediaTime`, `HostTime`, `HostClock`, `FrameTiming`, `PixelSize`, `TimedFrame`.
2. `VideoSource` protocol (primary associated type `Frame`), `VideoSourceKind`, `VideoSourceState`, `VideoSourceError`, `VideoSourceEvent`.
3. `FrameSampler` — time-based sampling at a configurable rate, robust to clock jumps and loop restarts.
4. `LatestValueMailbox<Value>` — capacity-1 async mailbox; newer values displace older ones and are counted as dropped.
5. `RateCounter`, `LatencyStats`, `PipelineMetrics` recorder + snapshot.
6. `NormalizedRect` (top-left origin convention, Vision bottom-left conversion), `NormalizedQuad`.
7. `RecognizedTextObservation`, `OCRResult`, `OCRConfiguration`, `OCRService` protocol.
8. `AppSettings` (Codable, growable).

## Confirmed Starting Point
- `Packages/KoubutsuCore` contains only `CoreInfo.swift` and a smoke test (Phase 1.1.0).

## Scope For This Phase
### In
- Types + unit tests above. Only Foundation and Synchronization imports.
### Out
- Any Apple-framework adapter (VideoFrame with CVPixelBuffer, Vision) — 1.3.0/1.5.0.
- Coordinate mapping to view space — Major 3.

## Recommended Implementation Direction
- Frame delivery is a synchronous handler invoked on the source's delivery queue (not an `AsyncStream`)
  so the display path has no buffering hop. Asynchronous consumers (OCR) decouple via the mailbox.
- Sampling keys on host arrival time, not presentation time, because presentation time restarts when a
  test video loops and is device-defined for capture.
- `NormalizedRect` uses top-left origin (image/UI convention). The single Vision-flip conversion lives
  on the type so no caller does ad hoc geometry.
- Thread safety via `Synchronization.Mutex` (available on Linux and iOS 18).

## Technical Plan
`Sources/KoubutsuCore/`
- `Media/MediaTime.swift`, `Media/FrameTiming.swift`, `Media/VideoSource.swift`
- `Pipeline/FrameSampler.swift`, `Pipeline/LatestValueMailbox.swift`
- `Metrics/RateCounter.swift`, `Metrics/LatencyStats.swift`, `Metrics/PipelineMetrics.swift`
- `Geometry/NormalizedRect.swift`
- `OCR/RecognizedTextObservation.swift`, `OCR/OCRService.swift`
- `Settings/AppSettings.swift`

## Test Plan
`swift test` covering: sampler cadence at 60→5 FPS (12-frame spacing), rate change, backwards time reset;
mailbox displacement/drop counts, await delivery, close semantics; rate counter window; latency percentiles;
rect flip round-trip and clamping; settings Codable round-trip and defaults.

## Key Decisions
- Core `VideoSource` is generic over `Frame: TimedFrame` so logic is testable without CoreVideo.
- Mailbox, not queue — enforces rule 2 in `CLAUDE.md` structurally.

## Expected Limitations At End Of Phase
- Types unused by the app until 1.3.0.

## What Comes Next
- 1.3.0 TestVideoSource + display renderer.

## Summary
Establish the tested, platform-agnostic contracts for timing, sources, sampling, backpressure, metrics, OCR results, and settings.
