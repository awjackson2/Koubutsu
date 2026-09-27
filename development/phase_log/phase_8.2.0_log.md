# Phase 8.2.0 Log — Dictionary data

## Phase
- **Number:** 8.2.0
- **Name:** Offline JMdict + KANJIDIC2 dictionary bundled with the app
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
A complete Japanese–English and kanji dictionary on the iPad, offline.

## Major Additions
- `Tools/build_dictionary.py`: JMdict_e + KANJIDIC2 → SQLite schema 1 (218,822 entries, 13,108 kanji;
  63.6 MB) → raw DEFLATE `App/Resources/Dictionary/koubutsu_dictionary.sqlite.deflate` (22.8 MB).
- Core: `DictionaryEntry` (kanji forms, readings with restrictions, senses with POS/misc/field/dialect/notes),
  `KanjiInfo`, `DictionaryStore`, `InMemoryDictionaryStore`, `Kana` (folding, script tests).
- App: `SQLiteDictionaryStore` (unpack once to Application Support, excluded from backup; read-only, locked,
  cached queries), `DictionaryProvider` (background load at launch).
- Settings → Licences; `docs/licences.md`.

## Major Changes
- None

## Progress Made
- Core tests pass; CI green on 23df616 incl. app test `bundledDictionaryAnswersLookups` (食べる, ボタン, 鍵, 敵).

## Key Decisions
- Generated data committed (23 MB) so the user's Mac build stays `git pull` + Run.
- CC BY-SA 4.0 attribution in app and docs; the derived database carries the same licence.

## Current Limitations
- No JLPT level for words; KANJIDIC2's old JLPT levels only for kanji.

## Artifacts Produced
- App/Resources/Dictionary/koubutsu_dictionary.sqlite.deflate

## What Comes Next
- 8.3.0 lookup engine.

## Summary
The whole of JMdict and KANJIDIC2, offline, on the iPad.
