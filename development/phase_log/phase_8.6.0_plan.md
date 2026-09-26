# Phase 8.6.0 Plan — Reading aids

## Phase
- **Number:** 8.6.0
- **Name:** Furigana over kanji on the live image; words being learned highlighted; known words left bare
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
A study-friendly alternative to replacing Japanese with English: keep the game's Japanese and add what a
learner needs to read it (umbrella 8.0.0).

## Immediate Goal
1. Overlay style setting: English (replace, as before) or Furigana (keep the original; small readings above
   each kanji run of each recognized line).
2. The English/Japanese button (T) cycles English → Furigana → original.
3. Words saved and still being learned are underlined in the live image (both styles' furigana mode);
   words marked known get no furigana.
4. Readings come from the dictionary segmentation of each line (cached per line text, computed off the main
   actor); conjugated words keep their okurigana (食べた → た over 食).

## Confirmed Starting Point
8.5.0 (`1e23ec1`): `WordBank.knownHeadwords/learningHeadwords`, `DictionaryLookup.segment`, `Furigana`.

## Scope For This Phase
### In
- Core: `ReadingAid.annotations(tokens:known:learning:)`, `ReadingAid.surfaceFurigana(surface:result:)`.
- App: `AppSettings.overlayStyle`, `ReadingAidModel` (cache + async), furigana rendering in `VideoOverlayView`.
### Out
- Per-character OCR boxes for live frames (proportional layout is used; study mode keeps exact boxes).

## Technical Plan
- Surface furigana: align the dictionary form's kanji runs with its reading, then assign those readings to the
  surface's kanji runs in order when the run counts match (conjugation only changes trailing kana).
- Rendering uses `CharacterLayout` boxes of each displayed line through `CoordinateMapper`.

## Test Plan
Core `swift test` (surface furigana for 食べさせられた/強くない/この先, known/learning handling, settings);
CI build/tests and screenshots (furigana series).

## Expected Limitations At End Of Phase
- Reading choice follows the best dictionary match; homographs (e.g. 今日 こんにち/きょう) may pick the common one.

## What Comes Next
- Major 8 complete; on-device study testing.

## Summary
Read the game in Japanese, with just enough help.
