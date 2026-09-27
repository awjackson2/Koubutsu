# Phase 10.7.2 Log — Visible translation failures

## Phase
- **Number:** 10.7.2
- **Name:** Visible translation failures
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.7.0), from the user's first iPhone run: every LOG row read "— NO TRANSLATION" with no notice
or Download prompt.

## Major Changes
- `TranslationController.apply(_:)` is the only place availability changes, and it always sets the notice. A
  request that fails with `.notInstalled` (or an unsupported pair) now goes through it, so the notice and its
  Download button appear even when startup reported the languages installed. Before, the flag flipped silently
  and every later line was skipped as unavailable.
- Other provider errors set the notice to the error text and are recorded on the history entry; a later success
  clears a transient notice.
- `DialogueEntry.failure` / `DialogueHistory.setFailure(_:for:)` (cleared by a translation).
- LOG rows show the reason: LANGUAGE NOT DOWNLOADED, NOT SUPPORTED ON THIS DEVICE, FAILED: …; VoiceOver reads it.

## Progress Made
- `swift test`: 188 tests pass (new `failureIsRecordedAndClearedByATranslation`).

## Key Decisions
- No second notice inside the deck: the layout's panels already render the notice + Download above the deck (and
  in every other layout) once the message is set; the defect was that it never was.

## Current Limitations
- Needs the user's device to confirm the actual cause (expected: Japanese→English not downloaded).

## Artifacts Produced
- `App/Translation/TranslationController.swift`, `App/UI/PortraitDeck.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Translation/DialogueHistory.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/DialogueHistoryTests.swift`.

## Summary
Translation problems now say what is wrong and offer the download instead of failing silently.
