# Phase 7.6.1 Log — Replace-in-place fixes from footage run 9

## Phase
- **Number:** 7.6.1
- **Name:** Replace-in-place fixes from footage run 9
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
🔧 Fix (Patch on 7.6.0): defects seen in the first replace-in-place screenshots on the Persona 3 Reload footage.

## Major Additions
- `OverlayPlacement.lineLimit`; the overlay caps lines at the fitted count and scales down (minimum 0.4) instead of wrapping into extra lines.
- `TranslationController.followTrackedGeometry()`: a shown box follows its text's latest position without re-translating.

## Major Changes
- Overlay boxes fully opaque (Japanese showed faintly through at 94%).
- Glyph-width estimate 0.52 → 0.6 em (semibold English was wider than estimated, breaking words mid-word).

## Progress Made
- Core 83 tests pass; app test `shownBoxFollowsTheTextWithoutRetranslating` added.

## Key Decisions
- None

## Current Limitations
- Low-confidence single glyphs (chalkboard, decorations) still get boxes; not filtered by design (7.5.0: no per-game heuristics).

## Artifacts Produced
- docs/screenshots/p3r76_replace_*.jpg (before the fix)

## What Comes Next
- Re-run footage screenshots after the fix.

## Summary
Replace-in-place boxes are opaque, never spill extra lines, and follow their text.
