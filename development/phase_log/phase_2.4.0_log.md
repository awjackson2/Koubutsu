# Phase 2.4.0 Log — AppleTranslationService and language availability

## Phase
- **Number:** 2.4.0
- **Name:** AppleTranslationService and language availability
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
On-device ja→en translation via Apple Translation, with availability check and download prompt.

## Major Additions
- `App/Translation/AppleTranslationService.swift`
- Download flow: `TranslationController.requestDownload` + `RootView.translationTask` + nonisolated `prepareDownload`
- `App/Translation/DemoTranslationService.swift` — labelled table translator for simulator screenshots (`--demo-translator`)

## Major Changes
- CI rejected sending the SwiftUI-provided session from the main actor; it now goes through a nonisolated helper.

## Progress Made
- CI: `appleServiceReportsAvailabilityWithoutCrashing` passes (simulator has no models).

## Key Decisions
- None

## Current Limitations
- Real translation latency/quality unmeasured until run on a device with the model installed.

## Artifacts Produced
- App/Translation/*

## What Comes Next
- 2.5.0.

## Summary
On-device Apple translation is wired in behind the abstraction.
