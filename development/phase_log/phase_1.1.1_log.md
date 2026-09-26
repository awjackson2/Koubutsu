# Phase 1.1.1 Log — SDK Verification Report and Deployment Target

## Phase
- **Number:** 1.1.1
- **Name:** SDK verification report, platform API record, deployment target
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Replace API assumptions with facts from the CI SDK and fix the platform floor.

## Major Additions
- `Tools/sdk_report.sh` v2 — extracts full declaration blocks (Vision Swift text recognition, Translation interface, AVCaptureDevice external type, sample-buffer renderer).
- `development/design/platform_apis.md` — verified API table per capability.

## Major Changes
- Deployment target 18.0 → **26.0** (`Tools/gen_xcodeproj.py`, regenerated project). CI green on the iOS 26.5 simulator (run 36206663818).

## Progress Made
- Confirmed: `AVCaptureDevice.DeviceType.external` is UVC on iPad (iOS 17); `TranslationSession(installedSource:target:)` (iOS 26.0) requires installed languages, so model download must go through SwiftUI `.translationTask`; Vision `RecognizedTextObservation` gains `textDirection` (vertical text) on iOS 26; `RecognizedText.boundingBox(for:)` gives per-substring boxes.

## Key Decisions
- iPadOS 26.0 floor; 26.4 translation strategies gated with `#available`.

## Current Limitations
- `Vision.NormalizedPoint`/`NormalizedRect` member names not yet extracted; confirmed by compilation in 1.5.0.

## Artifacts Produced
- `Tools/sdk_report.sh`, `development/design/platform_apis.md`, `Koubutsu.xcodeproj/project.pbxproj`.

## What Comes Next
- 1.2.0 → 1.5.0.

## Summary
API decisions now rest on the actual Xcode 26.6 / iOS 26.5 SDK; the app targets iPadOS 26.0.
