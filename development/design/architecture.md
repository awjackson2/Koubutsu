# Architecture

Last synced: Phase 1.2.0 (2026-09-26)

## Layers

```
┌──────────────────────────── App target (Koubutsu, iPadOS) ────────────────────────────┐
│ UI (SwiftUI)          RootView, DebugPanel, TranslationPanel, Overlay                 │
│ Composition           AppModel (@MainActor, @Observable) — owns pipeline & source     │
│ Adapters (Apple)      TestVideoSource, UVCVideoSource, VideoFrame(CVPixelBuffer),     │
│                       SampleBufferRenderer, VisionOCRService, AppleTranslationService │
└──────────────────────────────────────┬─────────────────────────────────────────────────┘
                                       │ depends on
┌──────────────────────────── KoubutsuCore (Swift package, Foundation only) ────────────┐
│ Media       MediaTime, HostTime, HostClock, FrameTiming, PixelSize, VideoSource        │
│ Pipeline    FrameSampler, LatestValueMailbox                                           │
│ Metrics     RateCounter, LatencyStats, PipelineMetrics                                 │
│ Geometry    NormalizedRect/Point/Quad                                                  │
│ OCR         RecognizedTextObservation, OCRResult, OCRConfiguration, OCRService         │
│ Settings    AppSettings                                                                │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

`KoubutsuCore` builds and tests on Linux (`swift test`); the app target builds only on macOS CI.

## Frame flow

```
VideoSource (delivery queue)
   │ frame handler, synchronous
   ├──▶ display renderer (enqueue; never waits)          ← display path
   └──▶ FrameSampler.shouldSample(hostTime)?             ← OCR tap, O(1)
            │ yes
            ▼
        LatestValueMailbox.offer(frame)   (displaced frame = dropped OCR frame)
            ▼
        OCR worker task: await next() → OCRService.recognize → OCRResult
            ▼
        @MainActor model update (debug panel / later: stabilizer → translation → overlay)
```

Invariants:
- The delivery handler does constant work: enqueue to display, a sampler check, a mailbox offer, metrics.
- No component retains frames beyond the mailbox slot and the one in-flight OCR request.
- Timing (`FrameTiming`) travels with every derived result, so latency is measurable at each stage.

## Coordinate convention

All recognized geometry is stored as `NormalizedRect` with a top-left origin in source-frame space.
Vision's bottom-left rectangles are converted once in the Vision adapter. View-space mapping is owned by
the coordinate-mapping layer (Major 3).

## Clocks

`HostTime` is the host monotonic clock (`CACurrentMediaTime` on Apple = capture sample-buffer clock).
Presentation time (`MediaTime`) is per-source and restarts on test-video loops. Latency is always measured
in host time. Audio (Major 6) will be stamped in the same host domain.
