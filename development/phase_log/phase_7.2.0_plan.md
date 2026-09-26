# Phase 7.2.0 Plan — Video mode UI

## Phase
- **Number:** 7.2.0
- **Name:** Video mode UI
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Make local videos a usable mode: transport controls and easy import.

## Immediate Goal
1. `VideoTransportBar`: play/pause, −10 s/+10 s, scrubber with elapsed/total, loop toggle, import button; shown for file sources only.

## Confirmed Starting Point
7.1.0.

## Scope For This Phase
### In
- Transport bar in RootView
### Out
- Thumbnails / library management

## Recommended Implementation Direction
Scrubbing seeks on release to avoid seek storms.

## Technical Plan
`App/UI/VideoTransportBar.swift`, `App/UI/RootView.swift`.

## Test Plan
CI compile + screenshot showing the bar.

## Key Decisions
- None

## Expected Limitations At End Of Phase
- None

## What Comes Next
- 7.3.0.

## Summary
A transport bar turns file playback into Video mode.
