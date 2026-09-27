# Phase 10.3.1 Log — Real top safe-area inset

## Phase
- **Number:** 10.3.1
- **Name:** Real top safe-area inset
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.3.0), from the 3f6b578 iPhone screenshots: in compact portrait the video sat under the
Dynamic Island and the slim housing header was hidden behind the status bar.

## Major Changes
- Root cause: the root `GeometryReader` ignores the top safe area, so its proxy reports a top inset of 0; the
  compact portrait insets floored it at 20 pt (the island needs ~62 pt).
- `RootView.body` now nests the layout reader inside a reader that respects the safe area and reads the real top
  inset from it (`windowSafeInsets(_:top:)`); every layout takes `safe:` instead of reading the proxy.
- The regular layout uses `windowedInsets(for: .regular, safe:)` (same formula; iPad status bar 24 pt → stage
  still at y 62, as the 3f6b578 iPad screenshots confirm today).

## Progress Made
- Core tests unchanged (163 pass).

## Key Decisions
- Leading/trailing/bottom still come from the inner reader, which sits inside those edges, so nothing is counted
  twice.

## Current Limitations
- Verified by the next iPhone screenshots.

## Artifacts Produced
- `App/UI/RootView.swift`, `App/UI/CompactPortraitLayout.swift`, `App/UI/CompactLandscapeLayout.swift`.

## What Comes Next
- 10.5.0 already merged; Major 10 wrap-up.

## Summary
The iPhone portrait header and video clear the Dynamic Island.
