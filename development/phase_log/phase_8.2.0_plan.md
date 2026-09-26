# Phase 8.2.0 Plan — Dictionary data

## Phase
- **Number:** 8.2.0
- **Name:** Offline JMdict + KANJIDIC2 dictionary bundled with the app
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Study mode needs a Japanese–English dictionary and kanji data on the iPad, offline (umbrella 8.0.0).

## Immediate Goal
1. `Tools/build_dictionary.py` converts JMdict_e + KANJIDIC2 into one SQLite database (schema v1), compressed
   (raw DEFLATE) to `App/Resources/Dictionary/koubutsu_dictionary.sqlite.deflate` (~23 MB), committed so a Mac
   build needs only `git pull` + Run.
2. Core: `DictionaryEntry`, `KanjiInfo` (decoded from the per-row JSON), `DictionaryStore` protocol,
   `InMemoryDictionaryStore`, `Kana.foldToHiragana`.
3. App: `SQLiteDictionaryStore` (system SQLite3) — decompresses to Application Support on first use,
   looks up by folded form, reads kanji.
4. Settings → Licences: EDRDG attribution (CC BY-SA 4.0); `docs/licences.md`.

## Confirmed Starting Point
8.1.0 (`d8e6bdf`).

## Scope For This Phase
### In
- Builder script, generated data file, core models/protocol, app SQLite store, attribution.
### Out
- De-inflection and scanning (8.3.0); UI for entries (8.4.0).

## Technical Plan
- Schema: `entry(id, common, rank, json)`, `form(key, entry, kanji)` indexed on key, `kanji(literal, json)`,
  `meta`. JSON keys are short (`k`,`r`,`s`, …) to keep the file small; the core model maps them.
- Store opens read-only (`SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX`) behind a lock; decompression runs once
  in a background task, keyed by the bundled file's size + schema.

## Test Plan
Core `swift test` (JSON decoding on real rows, kana folding, in-memory store); CI build.

## Key Decisions
- Commit the generated data (23 MB) rather than build it in Xcode: the user builds on a Mac with plain Run.
- JMdict/KANJIDIC2 are CC BY-SA 4.0: attribution in the app and docs; the data file carries the same licence.

## Expected Limitations At End Of Phase
- No JLPT levels for words (JMdict has none); kanji carry KANJIDIC2's old JLPT levels.

## What Comes Next
- 8.3.0 lookup engine.

## Summary
The whole of JMdict and KANJIDIC2, offline, on the iPad.
