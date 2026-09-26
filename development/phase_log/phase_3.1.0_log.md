# Phase 3.1.0 Log — CoordinateMapper

## Phase
- **Number:** 3.1.0
- **Name:** CoordinateMapper
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Single tested conversion layer between normalized frame, pixel, displayed-video and view coordinates.

## Major Additions
- `CoordinateMapper`, `PlaneRect`, `PlanePoint`, `VideoContentMode`

## Major Changes
- None

## Progress Made
- `CoordinateMapperTests` (6) pass; screenshots show OCR boxes aligned with on-screen text (CI runs 13–15).

## Key Decisions
- None

## Current Limitations
- None

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/CoordinateMapper.swift

## What Comes Next
- 3.2.0.

## Summary
All coordinate math lives in one tested place.
