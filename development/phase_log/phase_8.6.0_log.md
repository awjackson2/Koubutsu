# Phase 8.6.0 Log — Reading aids

## Phase
- **Number:** 8.6.0
- **Name:** Furigana over kanji on the live image; learning highlights; known words bare
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_8.6.0_plan.md` (umbrella 8.0.0).

## Major Additions
- Core: `ReadingAid.surfaceFurigana` (dictionary-form alignment mapped onto the conjugated surface's kanji runs), `ReadingAid.annotations`; `AppSettings.overlayStyle` (english/furigana).
- App: `ReadingAidModel` (per-line cache, off-main computation, vocabulary invalidation outside view updates), furigana labels and learning underlines in `VideoOverlayView`, overlay button/T cycles English → furigana → original, Settings picker, `--furigana`; `DictionaryProvider.lookup` shared.

## Major Changes
- Furigana is drawn for the latest OCR lines, not the stabilized tracks, so readings disappear with their text (seen in CI screenshots: readings lingered over a vanished title).
- Fixed a Swift type-inference build error in the overlay marks.

## Progress Made
- Core 136 tests; CI green on a411d91 (iOS, IPA); screenshots: furigana けってい over 決定 on the menu, readings over the title.

## Key Decisions
- Proportional character layout on live frames (per-character OCR boxes only in study mode) to keep live OCR cheap.

## Current Limitations
- Reading choice follows the best match; homographs may pick the common reading.

## Artifacts Produced
- docs/screenshots/study860_furigana.jpg, docs/screenshots/study860_drag.jpg

## What Comes Next
- Major 8 complete; on-device study testing.

## Summary
Furigana over kanji on the live image; learning highlights; known words bare.
