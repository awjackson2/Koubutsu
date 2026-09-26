# Phase 3.0.0 Plan — Umbrella: coordinate mapping and spatial overlay

## Phase
- **Number:** 3.0.0
- **Name:** Umbrella: coordinate mapping and spatial overlay
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Second build target (§39): show English over or near the Japanese it translates, with verified geometry.

## Immediate Goal
1. Roadmap: 3.1.0 CoordinateMapper (core, tested) → 3.2.0 OCR box debug overlay → 3.3.0 translation overlay with layout + display modes. 3.4–3.9 reserved (covering original text, text-box detection, fades/tracking polish).

## Confirmed Starting Point
Major 2: stable blocks with normalized top-left boxes and translations on the main actor.

## Scope For This Phase
### In
- Mapper, box overlay, translation overlay
### Out
- Inpainting, dialogue-box background matching (future)

## Recommended Implementation Direction
All geometry in core (`CoordinateMapper`, `OverlayLayout`), SwiftUI only renders placements.

## Technical Plan
Roadmap checklist:
```
- [ ] 3.1.0 — CoordinateMapper (aspect fit/fill/stretch, pixel/view round trips)   deps: 1.2.0  risk: low
- [ ] 3.2.0 — OCR box debug overlay (quads) toggled by settings                     deps: 3.1.0  risk: low
- [ ] 3.3.0 — Translation overlay: OverlayLayout + VideoOverlayView + display modes    deps: 3.2.0  risk: med
```

## Test Plan
Core: mapper + layout tests on Linux. App: CI compile + overlay view builds; visual verification by the user in the simulator.

## Key Decisions
- Overlay layer sits in the same SwiftUI frame as the display layer, using `.aspectFit` = `AVLayerVideoGravity.resizeAspect`.

## Expected Limitations At End Of Phase
- No automated pixel-level overlay verification in CI.

## What Comes Next
- 3.1.0.

## Summary
Spatially correct translation overlays built on a single tested coordinate layer.
