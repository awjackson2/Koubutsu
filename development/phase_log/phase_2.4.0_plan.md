# Phase 2.4.0 Plan — AppleTranslationService and language availability

## Phase
- **Number:** 2.4.0
- **Name:** AppleTranslationService and language availability
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestone 6: real Japanese→English translation with Apple's on-device Translation framework behind the `TranslationService` protocol.

## Immediate Goal
1. `AppleTranslationService` actor using `TranslationSession(installedSource:target:)` (iPadOS 26), strategy-gated on 26.4 (`lowLatency`/`highFidelity`).
2. Availability via `LanguageAvailability.status(from:to:)` → `.installed/.needsDownload/.unsupported`.
3. Download path: SwiftUI `.translationTask` + `prepareTranslation()` driven by `TranslationController.downloadConfiguration`.
4. Error mapping from `Translation.TranslationError` to `KoubutsuCore.TranslationError`.

## Confirmed Starting Point
2.3.0 contracts/coordinator; SDK facts in `development/design/platform_apis.md`.

## Scope For This Phase
### In
- `App/Translation/AppleTranslationService.swift`
- download prompt wiring in `RootView`
### Out
- Cloud translators
- Context use (Apple API is sentence-level)

## Recommended Implementation Direction
Sessions are cached per language pair/quality inside the actor and dropped on error or after a download. The non-Sendable `TranslationSession` crosses into a `nonisolated` helper through `UncheckedSendableBox`; the actor never shares it concurrently with other state.

## Technical Plan
`App/Translation/AppleTranslationService.swift`; `TranslationController.requestDownload/downloadFinished`; `RootView.translationTask`.

## Test Plan
App test: availability call completes on the simulator (models are not installed there). Behavioural tests use a table translator (2.5.0).

## Key Decisions
- Only SwiftUI can prompt for downloads; everything else is UI-independent.

## Expected Limitations At End Of Phase
- Real translation latency/quality only measurable on a device with the ja→en model installed.

## What Comes Next
- 2.5.0 end-to-end translation panel.

## Summary
On-device Apple translation behind the app's translation abstraction, including the language-download flow.
