# Phase 10.7.2 Plan — Visible translation failures

## Phase
- **Number:** 10.7.2
- **Name:** Visible translation failures
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
🔧 Fix (Patch on 10.7.0), from the user's first iPhone run: every LOG row read "— NO TRANSLATION" and no status or
Download prompt appeared. `TranslationController.translate` flips `availability` to `.needsDownload` on a
`.notInstalled` error without setting `statusMessage`, so later lines are skipped silently as `.unavailable`;
other errors are kept only on the displayed item and never reach the history, the LOG or a message.

## Immediate Goal
1. A missing language pack (at startup or discovered by a failing request) always shows the notice + Download.
2. Other translation errors show a notice with the reason.
3. Each history entry records why it has no translation; the LOG shows LANGUAGE NOT DOWNLOADED / UNSUPPORTED /
   FAILED: reason / TRANSLATING instead of a generic line.

## Scope For This Phase
### In
- KoubutsuCore: `DialogueEntry.failure`, `DialogueHistory.setFailure(_:for:)`; `setTranslation` clears it. Tests.
- `TranslationController`: one `apply(_ availability:)` path for availability + message; errors recorded in history.
- `PortraitDeck`: reason text in LOG rows. The notice + Download already render in every layout's panels (above
  the deck in portrait) once `statusMessage` is set, so no second notice in the deck.
### Out
- Changing the translation provider or download flow itself.

## Test Plan
`swift test` (history failure recording/clearing). CI on iPad + iPhone. User re-run on device.

## Summary
Translation problems become visible and actionable instead of silent.
