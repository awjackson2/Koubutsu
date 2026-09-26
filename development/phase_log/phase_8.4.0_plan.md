# Phase 8.4.0 Plan — Word card

## Phase
- **Number:** 8.4.0
- **Name:** Full dictionary card for a looked-up word
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Everything needed to learn the tapped word, in one place (umbrella 8.0.0).

## Immediate Goal
1. Headword with furigana over each kanji run; kana reading; romaji (Hepburn).
2. Conjugation line: "食べさせられた = 食べる · causative → passive or potential → past".
3. Senses numbered with parts of speech and usage labels in plain English; other written forms/readings.
4. Kanji breakdown: meanings, on/kun readings, strokes, grade, JLPT, frequency (KANJIDIC2).
5. The sentence the word came from (word highlighted) and its translation.
6. Pronunciation (on-device Japanese voice) and the iPadOS system dictionary (monolingual if installed).
7. Other matches at the tapped position, switchable.

## Confirmed Starting Point
8.3.0 (`e9318a9`): `DictionaryLookup`, `WordSummary` in `StudyPanel`.

## Scope For This Phase
### In
- Core: `Furigana.align(written:reading:)`, `Romaji.hepburn(_:)`, `DictionaryLabels` (POS/misc/field names).
- App: `WordCardView` (sheet, medium/large detents), `Speaker` (AVSpeechSynthesizer ja-JP),
  `SystemDictionaryView` (`UIReferenceLibraryViewController`).
### Out
- Saving (8.5.0).

## Technical Plan
- Furigana: split the written form into kanji/kana runs; kana runs must appear in the reading; kanji runs take
  what lies between (backtracking); on failure the whole reading sits over the whole word.
- Romaji: digraphs, っ gemination, ん before vowels/y as n', ー repeats the previous vowel; katakana folded first.

## Test Plan
Core `swift test` (alignment incl. 取り扱い, お前, 食べる, 今日 (no split); romaji cases; labels); CI build.

## Expected Limitations At End Of Phase
- Furigana for irregular readings (今日 = きょう) is placed over the whole word (correct but not per character).

## What Comes Next
- 8.5.0 word bank and review.

## Summary
Tap a word, learn everything about it.
