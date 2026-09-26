# Architecture

Last synced: Phase 7.6.0 (2026-09-26)

## Layers

```
┌──────────────────────────────── App target (Koubutsu, iPadOS 26) ─────────────────────────────────┐
│ UI (SwiftUI)     RootView · VideoDisplayView · VideoOverlayView (replace in place) ·                │
│                  TranslationPanel · VideoTransportBar · DebugPanel · SettingsView                  │
│ Composition      AppModel (@MainActor @Observable): source lifecycle, settings, hot-plug, benchmark │
│                  TranslationController (@MainActor): stabilizer → history → coordinator → displayed │
│ Adapters         Video: TestVideoSource · UVCVideoSource · VideoFrame · SampleBufferRenderer        │
│                  Pipeline: FramePipeline · SampledFrameTap · OCR: VisionOCRService · OCRWorker      │
│                  Translation: AppleTranslationService · Audio: CaptureAudioService                  │
│                  Capture: CaptureDeviceMonitor · Performance: PerformanceMonitor · BenchmarkRunner  │
└──────────────────────────────────────────────┬─────────────────────────────────────────────────────┘
                                               │ depends on
┌──────────────────────────────── KoubutsuCore (Foundation only, Linux-tested) ─────────────────────┐
│ Media       MediaTime · HostTime · HostClock · FrameTiming · VideoSource · VideoFormat · Playback  │
│ Pipeline    FrameSampler · LatestValueMailbox                                                      │
│ Metrics     RateCounter · LatencyStats · PipelineMetrics                                           │
│ Geometry    NormalizedRect/Point/Quad · CoordinateMapper · PlaneRect                               │
│ OCR         RecognizedTextObservation · OCRResult · OCRConfiguration · OCRService                  │
│ Text        TextNormalizer · TextBlockGrouper · TextStabilizer                                     │
│ Translation TranslationService · TranslationRequest/Context · TranslationCache ·                   │
│             TranslationCoordinator · DialogueHistory                                               │
│ Overlay     OverlayLayout            Capture  CaptureFormatSelector                                │
│ Benchmark   OCRBenchmark             Settings AppSettings                                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Data flow

```
TestVideoSource (AVPlayerItemVideoOutput pull, 2× source rate)   UVCVideoSource (AVCaptureVideoDataOutput)
                   └──────────────┬─────────────────────────────────────────┘
                                  ▼  frame handler, synchronous, source delivery queue
                           FramePipeline.handle
            ┌─────────────────────┼────────────────────────────────┐
            ▼                     ▼                                ▼
 SampleBufferRenderer      PipelineMetrics              SampledFrameTap (FrameSampler, 10 FPS default)
 (AVSampleBufferDisplay-   (received/displayed)                    │ LatestValueMailbox (newest frame only)
  Layer, display-                                                  ▼
  immediately) — never                                  OCRWorker (detached task, one request in flight)
  waits for anything                                               │ VisionOCRService (RecognizeTextRequest, ja)
                                                                   ▼
                                                   @MainActor: AppModel.latestOCR, TranslationController
                                                                   │ TextStabilizer (grouping, tracking;
                                                                   │  emits on first reading, re-emits on change)
                                                                   ▼ .stabilized(StableText)
                                                   DialogueHistory + TranslationCoordinator
                                                     (LRU cache, in-flight dedup, metrics)
                                                                   │ AppleTranslationService (on device)
                                                                   ▼
                                                   displayed → VideoOverlayView (default) / TranslationPanel
                                                     (CoordinateMapper + OverlayLayout: opaque box over
                                                      each Japanese block, English fitted inside; the
                                                      block's previous English stays up while it updates)
```

Invariants:
- The delivery handler does constant work: display enqueue, metrics, a sampler check, a mailbox offer.
- At most one frame waits for OCR and one is being recognized; everything else is dropped and counted.
- `FrameTiming` travels with OCR results, stable text and translations: capture→OCR, capture→translation and
  capture→shown latencies are measured, not estimated.

## Coordinate convention

Recognized geometry is stored as `NormalizedRect` (top-left origin, source-frame space). Vision's
bottom-left rectangles/points are converted exactly once in `VisionOCRService` (including ROI → full-frame).
`CoordinateMapper` is the only code converting to pixels or view points; the overlay uses `.aspectFit`,
matching the display layer's `.resizeAspect`.

## Clocks

`HostTime` = host monotonic clock (`CACurrentMediaTime`), the clock capture sample buffers are stamped in.
Test-video frames are stamped with the host time they were pulled. Audio tap buffers (UAC) carry
`AVAudioTime` host times in the same domain for future synchronization.

## Video mode

A file source is game mode on a file: the same pipeline, plus `PlaybackControlling` (play/pause/seek/loop)
used only by `VideoTransportBar`. A paused file re-delivers its last frame every 250 ms so OCR keeps
running. Seeking or looping (media time going backwards) clears what is on screen.

## Lifecycle

`AppModel` owns every transition: select/start/stop source, background → stop, foreground → restart,
capture device connect → auto-switch (setting), disconnect → error + wait, reconnect → restart.

## Privacy

OCR (Vision) and translation (Apple Translation, installed-language sessions) run on device. Video frames
and text are never sent off device. `TranslationService.sendsDataOffDevice` exists so any future cloud
backend must be explicitly surfaced and consented to.
