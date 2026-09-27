# Phase 10.7.4 Plan — Translation failure recovery and backoff

## Phase
- **Number:** 10.7.4
- **Name:** Translation failure recovery and backoff
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
🔧 Fix (Patch on 10.7.3), from the user's Xcode console: every on-screen line produced a translation attempt that
failed with `TranslationErrorDomain Code=16` ("Failed to determine all preflight information", "Failed to wait
for languages to finish downloading"). The error does not match `Translation.TranslationError.notInstalled`, so it
arrives as `.failed`, availability never flips to needs-download, and the app retries every line.

## Immediate Goal
1. After a `.failed`/`.unavailable` translation error the controller re-queries `LanguageAvailability`; if the
   pair is not installed it switches to the needs-download state (notice + Download) and stops per-line attempts.
2. Repeated failures open a circuit breaker: after 3 consecutive failures, translation pauses with exponential
   backoff (15 s doubling to 120 s); a success resets it. Paused lines are labelled in the LOG and the notice
   says when translation resumes and why.
3. A Download attempt or a successful translation clears the pause.

## Scope For This Phase
### In
- KoubutsuCore `TranslationBackoff` (pure, Linux-tested).
- `TranslationController`: availability recheck on failure, backoff gate, messages.
### Out
- Guessing undocumented error codes (rule 11): recovery relies on the documented availability API instead.

## Test Plan
`swift test` (backoff opens after the threshold, doubles to the cap, resets on success). CI on iPad + iPhone.

## Summary
A device without working language assets gets one clear notice instead of a failed attempt per line.
