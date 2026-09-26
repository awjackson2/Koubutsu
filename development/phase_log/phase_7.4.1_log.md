# Phase 7.4.1 Log — OCR keeps reading a paused frame; footage screenshots

## Phase
- **Number:** 7.4.1
- **Name:** OCR keeps reading a paused frame; footage screenshots
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Pausing on a line must still produce OCR and translation; capture app screenshots on footage in CI.

## Major Additions
- Still-frame re-delivery every 250 ms in `TestVideoSource`
- Launch options `--select-video`, `--start-at`, `--pause-after`
- Tools/ci_footage_screenshots.sh

## Major Changes
- None

## Progress Made
- CI green on 90bfc33

## Key Decisions
- Re-delivered frames keep their presentation time

## Current Limitations
- None

## Artifacts Produced
- App/Video/TestVideoSource.swift
- Tools/ci_footage_screenshots.sh

## What Comes Next
- See Major 7 umbrella ([phase_7.0.0_plan.md](phase_7.0.0_plan.md)).

## Summary
A paused video keeps being read.
