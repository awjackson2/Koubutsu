# Phase 10.7.4 Log — Translation failure recovery and backoff

## Phase
- **Number:** 10.7.4
- **Name:** Translation failure recovery and backoff
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.7.3), from the user's Xcode console: `TranslationErrorDomain Code=16` failures ("Failed to
determine all preflight information", "Failed to wait for languages to finish downloading") on every line; the
error arrives as `.failed`, so the app never switched to needs-download and retried each line.

## Major Changes
- `TranslationBackoff` (KoubutsuCore): after 3 consecutive failures requests pause 15 s, doubling to 120 s; a
  success or a Download attempt closes it.
- `TranslationController`: on `.failed`/`.unavailable` it re-queries `LanguageAvailability` (one check at a
  time); needs-download or unsupported switches to that state (notice + Download, no per-line attempts). While
  paused, lines are labelled PAUSED AFTER REPEATED FAILURES and the notice gives the pause length, the last error
  and the manual download location.

## Progress Made
- `swift test`: 191 tests pass (3 new `TranslationBackoffTests`).

## Key Decisions
- No mapping of undocumented error codes (rule 11): recovery uses the documented availability API.
- The backoff is not reset by `reset()` (called on every loop/seek), only by success or a Download attempt, so
  looping footage cannot defeat it.

## Current Limitations
- If `LanguageAvailability` reports the pair installed while the provider still fails, only the backoff and the
  notice apply; the assets must be repaired in Settings.

## Artifacts Produced
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Translation/TranslationBackoff.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/TranslationBackoffTests.swift`,
  `App/Translation/TranslationController.swift`.

## Summary
A device with broken language assets gets one clear notice and a paused provider instead of a failure per line.
