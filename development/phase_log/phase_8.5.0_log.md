# Phase 8.5.0 Log — Word bank & review

## Phase
- **Number:** 8.5.0
- **Name:** Save words with context; FSRS review; Anki export
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_8.5.0_plan.md` (umbrella 8.0.0).

## Major Additions
- Core: `SavedWord`, `ReviewCard`, `ReviewRating`, `FSRS` (4.5 defaults, 90 % retention, 5-minute relearn), `WordBank` (dedupe, due, known/learning), `AnkiExport` (Anki 2.1.55+ headers, Basic note type, ruby furigana, tags).
- App: `WordBankStore` (Documents/WordBank JSON + JPEG line crops), save from the card with sentence, translation, source, media time and crop; `WordBankView` (search, due, known, delete, card, Anki export via Files), `ReviewView` (space, 1–4, interval previews, failed cards return in-session); control-bar Words button with due count; W/R keys.

## Major Changes
- None

## Progress Made
- Core 132 tests at the time; app test `savesPersistsReviewsAndDeletes` green on a411d91.

## Key Decisions
- Everything stays on the device; export is an explicit file the learner shares.

## Current Limitations
- No .apkg packages; fixed retention target.

## Artifacts Produced
- None

## What Comes Next
- Next roadmap item (umbrella 8.0.0).

## Summary
Save words with context; FSRS review; Anki export.
