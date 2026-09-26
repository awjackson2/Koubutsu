# Phase 7.5.0 Log — Reframe Video mode; remove analysis layers

## Phase
- **Number:** 7.5.0
- **Name:** Reframe Video mode; remove analysis layers
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Product direction clarified: replace Japanese with English in real time wherever it appears; Video mode behaves exactly like game mode. Analysis, transcript, speaker and HUD layers removed.

## Major Additions
- Grouping height ratio 0.75–1.33 so a smaller name label stays its own block (tested on measured geometry)

## Major Changes
- Deleted TranscriptBuilder, HUDFilter, speaker extraction, VideoAnalyzer, TranscriptView, FootageAnalysisTests, `--show-transcript`, `hideHUDText`
- Footage workflow reduced to screenshots
- Major 7 roadmap rewritten

## Progress Made
- 79 core tests pass; CI on 9b18f8b

## Key Decisions
- Every text region is treated the same; no dialogue/HUD/speaker classification

## Current Limitations
- None

## Artifacts Produced
- see commit 9b18f8b

## What Comes Next
- See Major 7 umbrella ([phase_7.0.0_plan.md](phase_7.0.0_plan.md)).

## Summary
Video mode is game mode on a file again.
