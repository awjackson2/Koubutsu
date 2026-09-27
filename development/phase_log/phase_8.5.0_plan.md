# Phase 8.5.0 Plan — Word bank & review

## Phase
- **Number:** 8.5.0
- **Name:** Save words with context; FSRS review; Anki export
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Close the loop from "found a word" to "learned it" (umbrella 8.0.0).

## Immediate Goal
1. Save from the word card: word, reading, meanings, sentence + translation, source name and media time, and a
   cropped image of the line from the frozen frame.
2. Word bank screen (W): search, due count, known/learning status, delete, open the card.
3. Review screen (R): due words; front = word + sentence + crop; back = furigana, reading, romaji, meanings,
   translation; Again/Hard/Good/Easy with interval previews; FSRS-4.5 scheduling.
4. Anki export: tab-separated file with Anki import headers (Basic note type, HTML ruby furigana, tags).
5. Persistence in Documents/WordBank (JSON + JPEG crops), on device only.

## Confirmed Starting Point
8.4.0 (`7565e8f`): `WordCardView` with an `onSave` hook.

## Scope For This Phase
### In
- Core: `SavedWord`, `ReviewCard`, `FSRS` (4.5 default weights), `WordBank`, `AnkiExport`.
- App: `WordBankStore`, save action, `WordBankView`, `ReviewView`, control-bar entries and shortcuts.
### Out
- Cloud sync; .apkg packages; custom FSRS parameters.

## Technical Plan
- FSRS-4.5: S0 = w[G-1]; D0 = w4 − (G−3)·w5; R = (1 + 19/81·t/S)^−0.5; success
  S' = S·(e^w8·(11−D)·S^−w9·(e^{w10(1−R)}−1)·hard/easy + 1); lapse S' = min(S, w11·D^−w12·((S+1)^w13−1)·e^{w14(1−R)});
  D' = w7·D0(4) + (1−w7)(D − w6(G−3)), clamped 1…10; interval = S at 90 % retention.
  Again schedules a 5-minute relearn step.

## Test Plan
Core `swift test` (FSRS monotonicity/known values, bank dedupe/due/known, TSV escaping and headers);
CI build/tests.

## Expected Limitations At End Of Phase
- Retention target fixed at 90 %.

## What Comes Next
- 8.6.0 reading aids.

## Summary
Every word you look up can become a card you actually remember.
