# Phase 3.2.0 Log — OCR bounding-box debug overlay

## Phase
- **Number:** 3.2.0
- **Name:** OCR bounding-box debug overlay
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Draw Vision quads over the video to verify mapping.

## Major Additions
- `VideoOverlayView` box layer (quads, toggled by `showOCRBoxes`)

## Major Changes
- None

## Progress Made
- Visible in `docs/screenshots/ci15_panel_*` — boxes align with dialogue lines and menu items.

## Key Decisions
- None

## Current Limitations
- Boxes lag video by OCR latency by design.

## Artifacts Produced
- App/UI/VideoOverlayView.swift

## What Comes Next
- 3.3.0.

## Summary
OCR geometry is visibly correct over the game.
