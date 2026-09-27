# Phase 8.3.0 Log — Lookup engine

## Phase
- **Number:** 8.3.0
- **Name:** De-inflection and longest-match dictionary lookup
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_8.3.0_plan.md` (umbrella 8.0.0).

## Major Additions
- `WordType` (terminal: ichidan, godan, kuru, suru, suru-noun, i-adjective; intermediate: polite, te), `WordType.of(partsOfSpeech:)`.
- `Deinflector`: ~300 suffix rules (godan rows generated) covering polite, past, te, negative (ない/なかった/ず/ずに), -たい, potential, passive, causative, causative-passive, volitional, imperative, なさい, conditionals (ば/たら), te-auxiliaries (いる/る/おく/しまう/ください), contractions (ちゃう/じゃう/とく/どく), adjective forms, noun + する, masu stem.
- `DictionaryLookup`: `lookup` (prefixes longest first, type-checked matches), `segment` (lowest-cost split: word 1, kana-for-kanji 1.5, unknown 2), `word(at:)` (first segment word, then other matches); `LookupResult.headword/reading`.
- Study panel: tap widens the highlight to the word and shows headword, reading, conjugation chain and first senses; drag lists the words of the phrase.

## Major Changes
- Hiragana never matches katakana-only entries (がいる ≠ ガイル); kana written as the entry is usually written (particles, uk words) outranks kana standing for a kanji word (が ≠ 画).
- Te-auxiliary rules anchored on て/で (a bare る rule produced nonsense chains such as 思ったろ).

## Progress Made
- Core 122 tests (29 conjugation cases, lookup, segmentation); probe over the full JMdict on Linux: game dialogue and manual text segment correctly in ~1–3 ms per phrase.

## Key Decisions
- Rule table written from grammar (not derived from GPL-licensed reader data).
- Segmentation by cost rather than greedy longest match keeps particles separate.

## Current Limitations
- All-kana text without spaces is ambiguous (かぎがひつようです splits as かぎ|がひつ|ようです).
- Homographs follow commonness (いる → 要る before 居る; both listed).

## Artifacts Produced
- None

## What Comes Next
- Next roadmap item (umbrella 8.0.0).

## Summary
De-inflection and longest-match dictionary lookup.
