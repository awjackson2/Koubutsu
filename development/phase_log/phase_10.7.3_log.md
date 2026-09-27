# Phase 10.7.3 Log — Download button feedback and outcome

## Phase
- **Number:** 10.7.3
- **Name:** Download button feedback and outcome
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.7.2), from the user's device: the Download button appeared to do nothing.

## Major Changes
- `isPreparingDownload`: the notice shows PREPARING (button hidden) from the tap until the attempt ends; a
  30 s safeguard returns the button if the system never runs the task.
- Repeated taps re-run the download task (`Configuration.invalidate()` when a configuration is still set).
- `downloadFinished` refreshes availability first, then reports the outcome, so a `prepareTranslation()` error
  is no longer overwritten; a still-missing language says so and names Settings → Apps → Translate.
- If translation still fails with "not installed" after a Download attempt while Apple lists the pair as
  installed, the notice explains the mismatch and points to the manual download.
- Notice text wraps instead of truncating.

## Current Limitations
- Which of these cases the device is in is only known after the user taps Download on this build.

## Artifacts Produced
- `App/Translation/TranslationController.swift`, `App/UI/TranslationPanel.swift`.

## Summary
The Download button visibly works and always reports what happened.
