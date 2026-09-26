# Phase 9.4.1 Log — Monitor frame fixes

## Phase
- **Number:** 9.4.1
- **Name:** Header clearance and full-height housing
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
🔧 Fix (Patch on 9.4.0), from the 9.4.0 CI screenshots: the header text sat directly under the status bar, and in
portrait the space between the housing and the chrome was bare black.

## Major Additions
- Maker's plate under the housing ("KOUBUTSU MONITOR SYSTEM · MODEL KB-09", よむ・わかる・おぼえる).

## Major Changes
- `VideoStageLayout.headerHeight` 30 → 38; header drawn 34 pt above the stage.
- Housing fills the window (hairline at the housing's bottom edge); chrome overlays it.

## Progress Made
- Core tests updated (top inset 62).

## Key Decisions
- The video stays the same size within windowed mode; only 8 pt of top inset added.

## Current Limitations
- Verified by CI screenshots only; no on-device check yet.

## Artifacts Produced
- `App/Theme/MonitorFrame.swift`, `VideoStageLayout.swift`, `VideoStageLayoutTests.swift`.

## What Comes Next
- Major 9 complete.

## Summary
The monitor header clears the status bar and the console fills the window.
