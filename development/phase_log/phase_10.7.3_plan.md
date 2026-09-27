# Phase 10.7.3 Plan — Download button feedback and outcome

## Phase
- **Number:** 10.7.3
- **Name:** Download button feedback and outcome
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
🔧 Fix (Patch on 10.7.2), from the user's device: tapping Download "does nothing".
Causes found in `TranslationController`:
1. `downloadFinished` writes the error to `statusMessage`, then `refreshAvailability()` overwrites it with the
   generic needs-download text — any failure of `prepareTranslation()` is invisible.
2. No state while the system prompt/download runs; nothing visibly changes on tap.
3. When `LanguageAvailability` already reports the pair installed, `prepareTranslation()` returns immediately with
   nothing to download, the next request fails with `.notInstalled` again and the same notice returns.
4. A repeated tap with a configuration already set does not re-run `.translationTask`.

## Immediate Goal
1. Tapping Download shows PREPARING… (button disabled) until the attempt ends.
2. The outcome is always reported: download error text; or, when Apple reports the languages installed but
   translation still fails, a message naming where to download them manually (Settings → Apps → Translate, or
   General → Language & Region → Translation Languages) plus what Apple reported.
3. Repeated taps re-trigger (`Configuration.invalidate()`).

## Scope For This Phase
### In
- `TranslationController`: `isPreparingDownload`, `requestDownload()` re-trigger, `downloadFinished` ordering and
  outcome messages, availability recorded for the message.
- `TranslationPanel`: PREPARING… state; notice text wraps.
### Out
- Replacing Apple Translation.

## Test Plan
CI on iPad + iPhone; user taps Download on device.

## Summary
The Download button visibly works and always says what happened.
