# Phase 1.1.1 Plan — SDK Verification Report and Deployment Target

## Phase
- **Number:** 1.1.1
- **Name:** SDK verification report, platform API record, deployment target
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Replace assumptions about Apple APIs with facts from the CI SDK, and lock the deployment target.

## Immediate Goal
1. `Tools/sdk_report.sh` v2 extracts complete declaration blocks (Vision `RecognizeTextRequest`, `RecognizedTextObservation`, `ImageRequestHandler`; full Translation interface; AVCaptureDevice external type; sample-buffer renderer).
2. `development/design/platform_apis.md` records verified APIs, availability, and the chosen implementation per capability.
3. App deployment target set to iPadOS 26.0 (generator constant; project regenerated).

## Confirmed Starting Point
- First report (Phase 1.1.0 CI run): Xcode 26.6 / iOS SDK 26.5. `TranslationSession(installedSource:target:)` is `@available(iOS 26.0)`; `LanguageAvailability` iOS 18; `VNRecognizeTextRequestRevision3` iOS 16.

## Scope For This Phase
### In
- Report script, design doc, deployment target change.
### Out
- Any use of the APIs (1.3.0+).

## Recommended Implementation Direction
iPadOS 26.0: required for a `TranslationSession` created outside SwiftUI (`init(installedSource:target:)`), which lets the
translation service be an ordinary actor behind `TranslationService` instead of being bound to a view's `.translationTask`.
Every USB-C iPad that runs iPadOS 26 supports external UVC capture (iPadOS 17+).

## Technical Plan
- Edit `Tools/sdk_report.sh`, `Tools/gen_xcodeproj.py` (`DEPLOYMENT_TARGET = "26.0"`), regenerate project.
- Push, read the report from CI logs, write `development/design/platform_apis.md`.

## Test Plan
- CI green with the new deployment target on the iOS 26.5 simulator.

## Key Decisions
- Deployment target iPadOS 26.0 (not 26.4): 26.4-only additions (translation `Strategy`, attributed-string translate) are optional and can be `#available`-gated.

## Expected Limitations At End Of Phase
- Device-only behavior (UVC enumeration) is still unverifiable until hardware exists.

## What Comes Next
- 1.2.0 core contracts.

## Summary
Turn the CI SDK into the source of truth for API decisions and fix the platform floor at iPadOS 26.0.
