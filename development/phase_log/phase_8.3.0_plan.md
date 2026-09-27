# Phase 8.3.0 Plan — Lookup engine

## Phase
- **Number:** 8.3.0
- **Name:** De-inflection and longest-match dictionary lookup
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Turn "the text from the tapped character on" into the dictionary word the learner meant, including conjugated
forms (食べさせられた → 食べる, causative + passive + past), as Yomitan-style readers do (umbrella 8.0.0).

## Immediate Goal
1. `Deinflector`: rule table (inflected suffix → base suffix, input/output word types, reason) applied
   recursively; covers ichidan, godan (all rows, 行く), する (incl. noun + する), 来る, i-adjectives:
   polite (ます/ました/ません/ませんでした/ましょう), past, て, negative (ない/なかった/ず), -たい, potential,
   passive, causative, causative-passive, volitional, imperative, conditional (ば/たら), ている/てる,
   てしまう/ちゃう, ておく/とく, adjective く/くて/かった/くない/さ/そう/すぎる, masu stem.
2. `DictionaryLookup.lookup(_:)`: tries prefixes longest first, de-inflects each, matches entries whose parts
   of speech fit the de-inflected type; ranks by match length, fewer transformations, commonness, frequency.
3. `DictionaryLookup.segment(_:)`: greedy longest-match tokenization of a phrase (drag selection, furigana).
4. Study panel: tap shows the best word (headword, reading, first glosses, conjugation chain); drag lists words.

## Confirmed Starting Point
8.2.0 (`23df616`): `DictionaryStore`, SQLite store, `Kana`.

## Scope For This Phase
### In
- Core `Deinflector`, `DictionaryLookup`, word-type mapping from JMdict POS; tests with an in-memory store.
- Minimal study-panel wiring (full card is 8.4.0).
### Out
- Furigana alignment, romaji, kanji breakdown (8.4.0).

## Technical Plan
- Word types are a bit set: terminal (v1, v5, vk, vs, vsNoun, adjI) and intermediate (masu, past, te, polite
  stem); only terminal types match entries. An unmodified prefix matches any entry.
- Godan rules are generated from the kana rows (う く ぐ す つ ぬ ぶ む る) to avoid hand-typed tables.

## Test Plan
Core `swift test`: ~25 conjugation cases, scanning/tie-breaking, segmentation; app test on the bundled
dictionary (食べさせられた, 行った).

## Expected Limitations At End Of Phase
- Greedy segmentation can split compounds wrongly where JMdict lacks the compound; rare dialectal forms missing.

## What Comes Next
- 8.4.0 word card.

## Summary
Tap any conjugated word and get its dictionary form, meaning and how it was conjugated.
