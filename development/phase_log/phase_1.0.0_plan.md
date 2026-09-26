# Phase 1.0.0 Plan — Umbrella: Prerecorded Video → Vision Japanese OCR Vertical Slice

## Phase
- **Number:** 1.0.0
- **Name:** Umbrella roadmap for Major 1 (foundation through visible Japanese OCR results)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Major 1 delivers the first real vertical slice:

```
Japanese gameplay video → real CVPixelBuffer frames → real Vision OCR → visible Japanese results (text, confidence, box, latency)
```

It also establishes every architectural seam the later Majors depend on (VideoSource abstraction,
frame/timestamp model, latest-frame backpressure, metrics, observation model) so translation, overlay,
UVC and UAC slot in without rewriting the pipeline.

It de-risks the single largest environmental constraint first: the development container is Linux with
no Xcode, so iOS compilation and Apple SDK verification must come from macOS CI before any
Apple-framework code is trusted.

## Immediate Goal
1. A native iPad app that builds on macOS CI for the iOS Simulator.
2. A Linux-testable `KoubutsuCore` Swift package holding all platform-agnostic logic.
3. A machine-generated SDK report that verifies (not assumes) Vision Japanese OCR, Translation, and external-capture APIs, and fixes the deployment target.
4. `TestVideoSource` playing a looping prerecorded video at source frame rate through the shared display renderer.
5. Frame tap exposing `CVPixelBuffer` + timestamps to the pipeline, with frame-rate diagnostics.
6. 5 FPS (configurable) Vision Japanese OCR on sampled frames via a latest-frame slot, results shown in a debug panel.

## Confirmed Starting Point
- Repository `awjackson2/Koubutsu`: `README.md` only, plus this phase scaffolding (`CLAUDE.md`, `development/phase_log/`, `.gitignore`).
- Development container: Ubuntu 24.04 x86_64, no Swift toolchain, no Xcode, network available (download.swift.org reachable). Japanese fonts (IPAGothic) installed; no ffmpeg.
- Repository is public → GitHub Actions macOS runners are available without minute cost.
- No capture hardware (CABLETIME CC19L) available. No test gameplay footage in the repository.

## Scope For This Phase (Major 1)
### In
- Xcode project, core package, CI (Linux + macOS), SDK verification report.
- Core models: frame/timestamp model, `VideoSource` protocol, frame sampler, latest-frame slot, metrics counters, `RecognizedTextObservation`, `NormalizedRect`, settings model skeleton.
- `TestVideoSource` (file-backed, looping, paced to source clock) and the shared display renderer.
- Synthetic deterministic Japanese test clip (committed, small) + import of user-supplied gameplay footage (not committed).
- `VisionOCRService` (Japanese, accurate/fast configurable), debug panel.
- `UVCVideoSource` stub type conforming to `VideoSource` that reports "unavailable" — no capture code.

### Out (later Majors)
- Text stabilization, translation, translation cache (Major 2).
- Coordinate mapper, bounding-box drawing, spatial overlay (Major 3).
- Profiling, physical-iPad runs, benchmark harness (Major 4).
- UVC capture implementation, device lifecycle (Major 5).
- UAC audio (Major 6).
- Dialogue history, learning mode, context-aware translation, ROI (reserved, Major 7+).

## Recommended Implementation Direction

### Two-tier code layout
```
Koubutsu.xcodeproj                 iPad app target + unit/UI test targets
App/                               @main, composition root, lifecycle
  Video/  OCR/  UI/  Platform/     Apple-framework code (AVFoundation, Vision, SwiftUI)
Packages/KoubutsuCore/             Pure Swift, Foundation-only, builds on Linux
  Sources/KoubutsuCore/{Media,Pipeline,OCR,Metrics,Settings}
  Tests/KoubutsuCoreTests/
Tools/                             SDK report script, test-clip generator
TestMedia/                         committed synthetic clip + manifest; local/ gitignored
.github/workflows/                 core-linux.yml, ios-build.yml, sdk-report.yml
development/design/                architecture.md, platform_apis.md (living docs)
```
Reason: the container can only test what compiles on Linux. Maximizing the pure-Swift surface
(sampling, backpressure, stabilization, caching, coordinate math) makes most deterministic logic
testable here; Apple-only code is kept thin and adapter-shaped.

### Frame model
`KoubutsuCore` defines timing and identity (`MediaTimestamp`: presentation time + host capture time,
frame index, source ID, dimensions). The app layer wraps it with the `CVPixelBuffer`
(`VideoFrame`, `@unchecked Sendable`, no pixel copy). Core logic is generic over the payload so the
sampler and latest-frame slot are testable with dummy payloads.

### Display path (decision to verify in 1.3.0)
Both sources feed one renderer built on `AVSampleBufferDisplayLayer`. `TestVideoSource` pulls
frames from `AVPlayerItemVideoOutput` on a display-link tick and enqueues them; `UVCVideoSource`
will enqueue `AVCaptureVideoDataOutput` buffers. This satisfies "same rendering path for test and live"
and keeps the frame tap and display on one fan-out point. Metal is deferred until measurements justify it.

### OCR path
Frame fan-out → `FrameSampler` (time-based, configurable FPS) → `LatestFrameSlot` (capacity 1,
counts overwrites as dropped OCR frames) → `VisionOCRService` (actor, off main) →
`[RecognizedTextObservation]` → `@MainActor` view model. The display path never awaits any of it.

### Platform API baseline (to be verified by 1.1.0 SDK report, not assumed)
| Capability | Expected API | Expected minimum |
|---|---|---|
| External UVC video on iPad | `AVCaptureDevice.DeviceType.external` via `AVCaptureDevice.DiscoverySession` | iPadOS 17 |
| Japanese OCR | `VNRecognizeTextRequest` (`recognitionLanguages = ["ja-JP"]`), or Swift `RecognizeTextRequest` | iOS 16 / iOS 18 |
| Programmatic translation (SwiftUI-hosted) | `TranslationSession` via `.translationTask` | iOS 18 |
| Translation session outside SwiftUI | `TranslationSession(installedSource:target:)` | iOS 26 (verify) |
| Language pack status | `LanguageAvailability` | iOS 18 |

Proposed deployment target: **iPadOS 26.0**, contingent on the SDK report and the physical iPad model.
Fallback: iPadOS 18.0 with the translation session hosted by a SwiftUI `.translationTask`.

## Roadmap checklist
Advisory mirror; progress is read from `phase_index.md`.

```
- [x] 1.1.0 — Project bootstrap: Xcode project (synchronized folders), KoubutsuCore package,
              CI (Linux swift test, macOS simulator build), launchable empty app shell
                                                   deps: none          risk: HIGH (pbxproj authored without Xcode)
- [x] 1.1.1 — SDK verification report: CI job dumps Xcode/SDK versions and greps SDK
              .swiftinterface files for Vision/Translation/AVCapture symbols; record results
              in development/design/platform_apis.md; lock deployment target
                                                   deps: 1.1.0         risk: med
- [x] 1.2.0 — Core pipeline contracts (Linux-tested): MediaTimestamp, frame identity,
              VideoSource protocol + state/error model, FrameSampler, LatestFrameSlot,
              RollingRateCounter/latency stats, RecognizedTextObservation, NormalizedRect,
              AppSettings skeleton                  deps: 1.1.0         risk: low
- [x] 1.3.0 — TestVideoSource + shared display renderer: file-backed looping playback at
              source rate, AVSampleBufferDisplayLayer renderer, synthetic Japanese test clip
              (generated, committed) + document-picker import of local footage,
              UVCVideoSource "unavailable" stub       deps: 1.2.0, 1.1.1  risk: med
- [x] 1.4.0 — Frame tap + diagnostics: fan-out of CVPixelBuffer frames with timestamps,
              received/displayed FPS, resolution, source label in a debug panel
                                                   deps: 1.3.0         risk: low
- [x] 1.5.0 — Vision Japanese OCR: VisionOCRService behind OCRService protocol, sampler +
              latest-frame slot wiring, observations with text/confidence/box/timestamp,
              OCR latency + dropped/processed counters, debug panel list
                                                   deps: 1.4.0         risk: med
- [x] 1.5.1 — OCR fixture test on macOS CI: known Japanese strings rendered into a frame,
              asserted through VisionOCRService on the iOS Simulator
                                                   deps: 1.5.0         risk: med
  (1.6–1.9 reserved for Major 1 follow-ons: e.g. settings UI for OCR rate/quality, source picker)
```

### Program roadmap beyond Major 1 (not yet decomposed; each gets its own MAJOR.0.0 umbrella)
- **Major 2 — Text state + translation:** normalization, change detection, temporal stabilization (typewriter reveal), `TranslationService` protocol with context-capable request type, `AppleTranslationService`, translation cache with hit/miss/latency metrics, JP/EN panel. (Milestones 5–7.)
- **Major 3 — Spatial overlay:** `CoordinateMapper` (Vision → source → displayed-video → view, aspect-fit/letterbox aware, Linux-tested), OCR box debug layer, translated overlay boxes. (Milestones 8–9.)
- **Major 4 — Performance + device:** signpost instrumentation, capture→overlay latency, thermal/memory, physical iPad run, deterministic benchmark clip with expected checkpoints. (Milestones 10–11, sections 33–34.)
- **Major 5 — UVC capture:** device discovery, format enumeration, 1080p60 selection, connect/disconnect lifecycle, source picker. (Milestone 12, section 29.)
- **Major 6 — UAC audio:** audio discovery, playback, A/V sync on a shared clock. (Milestone 13.)
- **Major 7+ — reserved:** dialogue history, context-aware translation, ROI, language-learning mode.

## Technical Plan
Per-Minor technical plans are written by `phase-tracker` at the start of each Minor. Cross-cutting constraints:
- Swift 6 language mode, strict concurrency. Capture/display callbacks on dedicated serial queues; OCR on an actor; UI state `@MainActor` `@Observable`.
- No pixel copies on the display path. The OCR path retains the `CVPixelBuffer` reference only while in the latest-frame slot or in flight.
- Metrics are lock-free or actor-owned; the UI samples them at ≤ 4 Hz rather than receiving per-frame updates.

## Test Plan
- `KoubutsuCore`: `swift test` on Linux locally and in `core-linux.yml`. Every Major 1 core type gets deterministic unit tests (sampler cadence, slot overwrite/drop counts, rate counters, rect math).
- App: `xcodebuild build` + `xcodebuild test` on an iOS Simulator destination in `ios-build.yml`. 1.5.1 adds a Vision fixture test.
- Manual: simulator run by the user (screen recording or screenshots) for 1.3.0–1.5.0 visual checks; physical iPad deferred to Major 4.

## Key Decisions
- **Core package + thin Apple adapters** — the only way to test logic in a Linux container; also improves testability generally.
- **macOS GitHub Actions as the compiler of record** — no Xcode locally; public repo makes it free. Every Apple-code phase is gated on it.
- **Hand-authored minimal `.xcodeproj` using file-system-synchronized groups** (Xcode 16+ format) — avoids per-file pbxproj entries and third-party generators. Fallback if CI rejects it: XcodeGen spec as a dev-time-only tool.
- **SDK facts come from CI introspection** — satisfies "do not invent APIs" without local Xcode.
- **Unified `AVSampleBufferDisplayLayer` renderer** for test and live sources — one display path, one frame fan-out point.
- **Synthetic Japanese test clip committed; real gameplay footage never committed** — deterministic tests without copyright exposure.
- **All phases on the session's designated branch** — branch-restricted environment; see `CLAUDE.md`.

## Expected Limitations At End Of Phase
- No translation, stabilization, or overlay.
- Bounding boxes shown as numbers only.
- UVC source is a stub; no audio.
- Performance measured only on the simulator/CI; no physical iPad numbers.
- Build verification depends on CI round-trips; the pbxproj may need iteration.

## What Comes Next
- Execute 1.1.0 via `phase-tracker` (loop driven by `phase-loop`).
- Decompose Major 2 into `phase_2.0.0_plan.md` once 1.5.x ships.

## Summary
Major 1 builds the foundation and first vertical slice: a CI-verified iPad app with a Linux-testable
core, SDK-verified API baseline, a looping prerecorded-video source rendered through the same display
path live capture will use, a zero-copy frame tap with timestamps, and 5 FPS Vision Japanese OCR behind
latest-frame backpressure, surfaced in a debug panel. Six Minors/Patches, dependency-ordered, highest risk
(project file authored without Xcode, unverified SDK APIs) first.
