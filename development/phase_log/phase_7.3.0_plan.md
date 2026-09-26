# Phase 7.3.0 Plan — Transcript and subtitle export

## Phase
- **Number:** 7.3.0
- **Name:** Transcript and subtitle export
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Turn a watched video into a timestamped JP/EN transcript (dialogue review, generated subtitles §25) and give the user a way to test OCR on long footage.

## Immediate Goal
1. Core `TranscriptBuilder`: entries keyed by stable text id with media start time, JP, EN, confidence; SRT (JP, EN, bilingual) and CSV export.
2. Transcript sheet: list with timestamps, tap to seek, share SRT/CSV.

## Confirmed Starting Point
7.2.0; `StableText.firstSeenFrame.presentationTime`.

## Scope For This Phase
### In
- Core builder + export + sheet
### Out
- Persisting transcripts between launches

## Recommended Implementation Direction
Entries end when their block is removed/invalidated; open entries end at the next entry or +3 s for export.

## Technical Plan
`Sources/KoubutsuCore/Translation/Transcript.swift`, `App/Translation/TranslationController.swift`, `App/UI/TranscriptView.swift`.

## Test Plan
Core: ordering, translation attach, end times, SRT/CSV formatting, discontinuity handling.

## Key Decisions
- Media time (presentation time) is the transcript clock so SRT lines up with the file.

## Expected Limitations At End Of Phase
- None

## What Comes Next
- 7.3.1.

## Summary
Any video yields an exportable bilingual transcript.
