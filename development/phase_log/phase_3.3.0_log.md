# Phase 3.3.0 Log — Translation overlay

## Phase
- **Number:** 3.3.0
- **Name:** Translation overlay
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Place English over the Japanese it translates.

## Major Additions
- `OverlayLayout` (core)
- translation layer in `VideoOverlayView`
- display modes panel / overlay / both

## Major Changes
- None

## Progress Made
- `OverlayLayoutTests` (4) pass; screenshots show English boxes placed at the menu items' positions.

## Key Decisions
- None

## Current Limitations
- Line-count estimate heuristic; overlay lags scene changes by OCR latency.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Overlay/OverlayLayout.swift
- App/UI/VideoOverlayView.swift

## What Comes Next
- Major 4.

## Summary
English appears where the Japanese is.
