# Phase 3.1.0 Plan — CoordinateMapper

## Phase
- **Number:** 3.1.0
- **Name:** CoordinateMapper
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Dedicated transformation layer (§15): normalized frame ⇄ source pixels ⇄ displayed video rect ⇄ view points.

## Immediate Goal
1. `CoordinateMapper` with aspect fit (letterbox/pillarbox), aspect fill (crop), stretch.
2. `PlaneRect`/`PlanePoint` platform-neutral view-space types.
3. Inverse mapping for touches (`normalizedPoint(fromView:)`, `normalizedRect(fromView:)`).

## Confirmed Starting Point
`NormalizedRect` top-left convention (1.2.0); Vision flip in the adapter (1.5.0).

## Scope For This Phase
### In
- Core mapper + tests
### Out
- Rotation/orientation (sources deliver upright frames)

## Recommended Implementation Direction
The Vision bottom-left → top-left conversion remains exactly once, in `VisionOCRService`; the mapper never sees Vision coordinates.

## Technical Plan
`Sources/KoubutsuCore/Geometry/CoordinateMapper.swift`.

## Test Plan
`CoordinateMapperTests`: letterbox, pillarbox, fill + visible rect, pixel and view round trips, hit testing in bars, invalid sizes.

## Key Decisions
- Mapper is a value type recomputed per layout pass — cheap and stateless.

## Expected Limitations At End Of Phase
- Assumes square pixels (true for UVC 1080p).

## What Comes Next
- 3.2.0 box overlay.

## Summary
One tested place for all coordinate conversions.
