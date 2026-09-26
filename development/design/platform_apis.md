# Platform APIs (verified against the SDK)

Last synced: Phase 1.1.1 (2026-09-26)

Source of truth: `Tools/sdk_report.sh` output from the `iOS` CI workflow (artifact `sdk-report`).
Verified toolchain: **Xcode 26.6 (17F113), Swift 6.3.3, iOS SDK 26.5**, runner image macos-26-arm64,
iOS simulator runtimes 26.2 / 26.4 / 26.5.

**Deployment target: iPadOS 26.0.**

## Video capture (UVC)

| API | Availability | Use |
|---|---|---|
| `AVCaptureDevice.DeviceType.external` | iOS 17.0 | "On iPad, external devices are those that conform to the UVC (USB Video Class) specification." Discovered via `AVCaptureDevice.DiscoverySession`. |
| `AVCaptureDevice.wasConnectedNotification` / `.wasDisconnectedNotification` | iOS 4.0 | Hot-plug handling (Major 5). |
| `AVCaptureDevice.DeviceType.microphone` | iOS 17.0 | Only one microphone device is exposed; audio routing chooses the physical input. UAC capture audio is therefore expected via the audio route (`AVAudioSession` inputs), to be verified on hardware (Major 6). |
| `NSCameraUsageDescription` | — | Required for capture authorization; set via generated Info.plist. |

No entitlement is required on iPadOS for external UVC devices (the entitlement noted in the header applies to visionOS < 3.0).

## Display

| API | Availability | Use |
|---|---|---|
| `AVSampleBufferDisplayLayer.sampleBufferRenderer` → `AVSampleBufferVideoRenderer` | iOS 17.0 | Single display path. `enqueue`, `status`, `requiresFlushToResumeDecoding`, `flush(removingDisplayedImage:completionHandler:)`. |
| `AVSampleBufferVideoRenderer.loadVideoPerformanceMetrics` | iOS 17.4 | Display-side dropped-frame metrics (Major 4). |
| `AVSampleBufferVideoRenderer.recommendedPixelBufferAttributes` | iOS 26.0 | Candidate for pixel format choice (Major 4). |
| `kCMSampleAttachmentKey_DisplayImmediately` | — | Frames shown on arrival; no timebase/buffering. |
| `AVPlayerItemVideoOutput` `itemTime(forHostTime:)`, `hasNewPixelBuffer(forItemTime:)`, `copyPixelBuffer(forItemTime:itemTimeForDisplay:)` | — | `TestVideoSource` frame pull. |

## OCR (Vision, Swift API)

| API | Availability | Notes |
|---|---|---|
| `RecognizeTextRequest` | iOS 18.0 | Revision `.revision3` only. Properties: `recognitionLevel` (`.accurate`/`.fast`), `recognitionLanguages: [Locale.Language]`, `automaticallyDetectsLanguage`, `usesLanguageCorrection`, `customWords`, `minimumTextHeightFraction: Float`, `regionOfInterest: Vision.NormalizedRect`, `supportedRecognitionLanguages`. |
| `RecognizeTextRequest.perform(on: CVPixelBuffer, orientation:)` / `perform(on: CMSampleBuffer, orientation:)` | iOS 18.0 | async; returns `[RecognizedTextObservation]`. |
| `RecognizedTextObservation` | iOS 18.0 | `topLeft/topRight/bottomRight/bottomLeft: Vision.NormalizedPoint` (bottom-left origin), `confidence`, `uuid`, `topCandidates(_:) -> [RecognizedText]`. iOS 26: `transcript`, `textDirection` (incl. `.topToBottom` — vertical Japanese), `isTitle`, `shouldWrapToNextLine`, `boundingRegion`. |
| `RecognizedText` | iOS 18.0 | `string`, `confidence`, `boundingBox(for: Range<String.Index>)` (per-substring boxes — useful for word-level overlays and learning mode). |
| `VNRecognizeTextRequestRevision3` (ObjC) | iOS 16.0 | Fallback; not used. |

Japanese availability is checked at runtime through `supportedRecognitionLanguages`.

## Translation

| API | Availability | Notes |
|---|---|---|
| `TranslationSession(installedSource:target:)` | iOS 26.0 | Session usable outside SwiftUI — **requires the language pair to be installed**. Basis for `AppleTranslationService`. |
| `TranslationSession(installedSource:target:preferredStrategy:)`, `Strategy.lowLatency/.highFidelity` | iOS 26.4 | Maps to the "Translation mode" setting; `#available(iOS 26.4, *)`-gated. |
| `translate(_:)`, `translations(from:)`, `translate(batch:)`, `prepareTranslation()`, `cancel()` (26.0), `isReady` (26.0), `canRequestDownloads` (26.0) | iOS 18.0+ | |
| `LanguageAvailability.status(from:to:)` → `.installed/.supported/.unsupported` | iOS 18.0 | Drives the "download languages" UI. |
| SwiftUI `.translationTask(_:action:)` + `prepareTranslation()` | iOS 18.0 | Only path that can prompt the user to download the ja→en model. |
| `TranslationError` incl. `.notInstalled` (26.0), `.unsupportedLanguagePairing`, `.nothingToTranslate` | iOS 18.0 | Mapped to app errors. |

Translation models are not available in the iOS Simulator in practice; CI tests must not depend on real translation.
