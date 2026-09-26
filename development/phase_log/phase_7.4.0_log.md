# Phase 7.4.0 Log — Speaker labels and HUD suppression

## Phase
- **Number:** 7.4.0
- **Name:** Speaker labels and HUD suppression
- **Status:** Completed (reverted in 7.5.0)
- **Date completed:** 2026-09-26

## Phase Goal
Reduce transcript noise seen on Persona 3 Reload footage.

## Major Additions
- Speaker extraction, `HUDFilter`, `hideHUDText` setting

## Major Changes
- None

## Progress Made
- Run 5: 426 → 182 transcript entries

## Key Decisions
- None that survived

## Current Limitations
- Game-specific heuristics; reverted in 7.5.0 per product direction

## Artifacts Produced
- (deleted) HUDFilter.swift

## What Comes Next
- See Major 7 umbrella ([phase_7.0.0_plan.md](phase_7.0.0_plan.md)).

## Summary
Heuristic noise reduction, later judged the wrong direction.
