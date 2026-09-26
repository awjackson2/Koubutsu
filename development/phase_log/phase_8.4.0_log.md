# Phase 8.4.0 Log — Word card

## Phase
- **Number:** 8.4.0
- **Name:** Full dictionary card for a looked-up word
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_8.4.0_plan.md` (umbrella 8.0.0).

## Major Additions
- Core: `Furigana.align(written:reading:)` (kanji/kana runs, backtracking, whole-word fallback), `Romaji.hepburn` (digraphs, っ, n', ー), `DictionaryLabels` (POS and usage names).
- App: `WordCardView` (furigana headword, reading, romaji, common tag, conjugation line, numbered senses with labels, other forms, KANJIDIC2 breakdown, sentence + translation, other matches), `FuriganaText`, `Speaker` (ja-JP voice), `SystemDictionaryView` (`UIReferenceLibraryViewController`).
- Automation: `--study-tap`, `--open-card`; CI screenshot series `study` and `card`.

## Major Changes
- Study panel entries open the card (tap or drag list).

## Progress Made
- Core 126 tests at the time; CI screenshots show the card for 強い tapped on the frozen dialogue (furigana つよ, tsuyoi, senses).

## Key Decisions
- Monolingual definitions via the iPadOS dictionary rather than bundled data (no suitable open Japanese–Japanese dictionary).

## Current Limitations
- Furigana for irregular readings spans the whole word.

## Artifacts Produced
- docs/screenshots/study860_card.jpg

## What Comes Next
- Next roadmap item (umbrella 8.0.0).

## Summary
Full dictionary card for a looked-up word.
