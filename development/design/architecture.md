# Architecture

Last synced: Phase 10.6.0 (2026-09-27)

## Layers

```
┌──────────────────────────────── App target (Koubutsu, iOS/iPadOS 26) ─────────────────────────────┐
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
│ Geometry    NormalizedRect/Point/Quad · CoordinateMapper · PlaneRect · VideoStageLayout ·          │
│             LayoutClass                                                                            │
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

## Text stability rules

- Only blocks containing kana or kanji are tracked; one-glyph blocks need confidence ≥ 0.5.
- Grouping: a list-item line (`1.`, `(2)`, `③`, `・`) starts its own block; a ≤2-character wrapped tail joins
  the line above at down to half its height; same-row fragments must have similar heights.
- Text in free space and growth of shown text (typewriter) are emitted on the first reading. Different text
  on a shown track, or a new block covering ≥50% of its area with a shown block, needs two readings.
- A track is removed after 0.6 s and at least two consecutive missed OCR results.

## Replacement box layout

`OverlayLayout.place`: box = Japanese block + 4 pt padding, font up to 70% of the Japanese line height. English
that would need less than 60% of that font widens the box rightward to the next Japanese on the same rows (or the
video edge); then the font goes down to 9 pt; then the box grows downward to the next Japanese below. Boxes never
cover other blocks' text.

## Screen layout

The video stage (`VideoStageLayout`) is a full-width, top-aligned 16:9 rect that depends only on the window size.
Transport bar, panels and control bar are a bottom-anchored overlay with fixed-height panels; showing or hiding
them never resizes or moves the video or its replacement boxes.

The app runs on iPad and iPhone (10.1.0). `LayoutClass.classify(width:height:)` picks the layout from the window
size, not the device: compact landscape when the window is under 500 pt tall, else compact portrait when under
600 pt wide, else regular (every full-screen iPad). `RootView` publishes it as `@Environment(\.layoutClass)`.
`VideoStageLayout.windowedInsets(for:safe:)` gives the stage insets per class: regular keeps the monitor housing;
compact portrait has a 24 pt header and 6 pt bezels; compact landscape stays inside all safe-area edges.

`RootView.body` dispatches to one layout per class (`regularLayout`, `CompactPortraitLayout.swift`,
`CompactLandscapeLayout.swift`), composed from shared pieces (`interactiveStage`, `transportBar`, `panels`,
`controlBar`, `studyPanel`):
- Regular: as above (monitor housing, chrome overlaid below the stage, fixed-height panels).
- Compact portrait (10.3.0): slim `CompactMonitorFrame` header, stage full width at the top, chrome in
  `VideoStageLayout.chromeRegion(below:)` under the stage (never over it), panels sharing its height. Full screen
  centres the stage (`centered`) and reveals the chrome by tap in the region below.
- Compact landscape (10.4.0): stage at full height inside the safe area with a hairline border; chrome is an
  overlay revealed by a tap (or the CONTROLS tab) and hidden after 4 s (not while VoiceOver runs); panels share
  `overlayPanelBudget` (bars + panels ≤ 60 % of the stage height).

Sheets (10.6.0) measure their own width (`SheetLayout`, `App/UI/SheetSupport.swift`) and stack rows below 500 pt or
at accessibility text sizes.

Full screen (`RootView.isFullScreen`) removes the chrome overlay and the status bar; a tap on the stage reveals
the chrome for 4 s. Holding on the stage hides the replacement overlay (peek at the original). Keyboard shortcuts
are invisible buttons kept in the hierarchy so they work with the chrome hidden. The idle timer is disabled
while a source runs (`keepScreenAwake`).

## Study mode (Major 8)

```
Study button (S) ── FramePipeline.latestFrame ──► StudySession
                                                   │ CGImage copy (display) + VisionOCRService(.study:
                                                   │   accurate, per-character boxes via RecognizedText.boundingBox(for:))
                                                   ▼
StudyView (frozen image, outlines, tap/drag, loupe) ─► StudySelection (CharacterLayout) ─► SelectedSpan
                                                   │
             DictionaryLookup (Deinflector + DictionaryStore) ◄── DictionaryProvider (SQLite, unpacked once)
                    │ word(at:) for a tap · segment(_:) for a drag
                    ▼
StudyPanel ─► WordCardView (Furigana, Romaji, DictionaryLabels, KANJIDIC2, Speaker, system dictionary)
                    │ Save
                    ▼
WordBankStore (Documents/WordBank: JSON + line crops) ─► WordBankView · ReviewView (FSRS) · AnkiExport
                    │ known / learning headwords
                    ▼
ReadingAidModel (segment + ReadingAid per line, cached) ─► VideoOverlayView furigana style
```

- Freezing never touches the display path: the live pipeline keeps running; the frozen image is drawn on top.
  File sources pause and resume.
- Dictionary: `Tools/build_dictionary.py` → `App/Resources/Dictionary/koubutsu_dictionary.sqlite.deflate`
  (JMdict + KANJIDIC2, CC BY-SA 4.0, attribution in Settings and `docs/licences.md`); keys are kana-folded forms.
- Lookup: suffix de-inflection rules with word-type constraints; tap = first word of the lowest-cost
  segmentation (words 1, kana-for-kanji 1.5, unknown characters 2), then all other matches.
- Overlay style: English (replace) or furigana (keep Japanese; readings over kanji runs, learning words
  underlined, known words bare). T cycles English → furigana → original.

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
