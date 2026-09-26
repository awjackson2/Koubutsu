# Phase 8.0.0 Plan — Study mode (umbrella)

## Phase
- **Number:** 8.0.0
- **Name:** Study mode: freeze, select, look up, save, review, reading aids
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Turn Koubutsu into a study tool. While playing (or watching a video), the learner freezes the frame, taps or
drags over an unknown word or phrase on the original image, gets a dictionary card (furigana, kana, romaji,
English senses, conjugation, kanji, sentence translation), saves it with its context, and reviews it later.
Live play can show furigana instead of English and highlight saved words.

## Immediate Goal
Ship 8.1.0–8.6.0 below, each independently usable.

## Confirmed Starting Point
`main` at `a2e4d36` (Phases through 7.8.0). Replace-in-place overlay, fixed video stage, full screen, recent lines.

## Scope For This Phase
### In
- Freeze-frame study view with tap/drag selection on the original image.
- Offline Japanese–English dictionary (JMdict) and kanji dictionary (KANJIDIC2), bundled, with attribution.
- Longest-match lookup with de-inflection; word card; word bank with FSRS review; Anki (TSV) export.
- Furigana reading aid on the live image; saved/known word handling.
### Out
- Pitch accent, example-sentence corpora, cloud sync, monolingual dictionary data (system dictionary is linked).

## Recommended Implementation Direction
Platform-agnostic logic (selection geometry, de-inflection, scanning, furigana alignment, romaji, FSRS, word
bank, TSV) in `KoubutsuCore`, Linux-tested. Apple-specific parts (frozen frame, Vision per-character boxes,
SQLite store, speech, system dictionary, UI) in the app behind protocols.

## Technical Plan
Roadmap checklist:
```
- [ ] 8.1.0 — Freeze & select: study button freezes the frame; accurate OCR with per-character boxes;
              tap selects a character, drag selects a region; selection text + translation
- [ ] 8.2.0 — Dictionary data: JMdict + KANJIDIC2 → SQLite (Tools/build_dictionary.py), bundled,
              DictionaryStore protocol + SQLite store, attributions screen
- [ ] 8.3.0 — Lookup engine: kana normalization, de-inflection rules, longest-match scanning (core)
- [ ] 8.4.0 — Word card: furigana alignment, romaji, senses/tags, conjugation chain, kanji breakdown,
              sentence + translation, speech, system dictionary
- [ ] 8.5.0 — Word bank & review: save with context (sentence, crop, source), FSRS scheduler, review
              screen, Anki TSV export
- [ ] 8.6.0 — Reading aids: furigana over kanji on the live image, saved words highlighted, known words skipped
```
Patches are appended per Minor as needed.

## Test Plan
Core `swift test` on Linux per phase; CI iOS build/tests, IPA and simulator screenshots per push.

## Key Decisions
- Dictionary bundled (offline, no network on device); JMdict/KANJIDIC2 are CC BY-SA 4.0 (EDRDG): attribution
  screen, derived data file under the same licence.
- Character selection uses Vision `RecognizedText.boundingBox(for:)` per-character boxes (verified in the SDK
  report), with a proportional fallback.
- FSRS (4.5 default parameters) in-app; Anki export as tab-separated text with Anki file headers.

## Expected Limitations At End Of Phase
- Readings for words not in JMdict come from the system tokenizer and can be wrong for rare readings.
- Gesture feel verified only on device by the user.

## What Comes Next
- 8.1.0.

## Summary
Freeze, tap, learn, save, review — and read with furigana while playing.
