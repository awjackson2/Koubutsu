# Phase 10.3.2 Log — Outer reader inside the safe area

## Phase
- **Number:** 10.3.2
- **Name:** Outer reader inside the safe area
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.3.1): the 8e14b3d iPhone screenshots showed the portrait stage still at ~43 pt under the
Dynamic Island. The outer `GeometryReader` added in 10.3.1 still carried the old `.ignoresSafeArea(edges: .top)`
from the modifier chain, so it reported a top inset of 0 as well.

## Major Changes
- `RootView.body`: the black background ignores the safe area (`.background(Color.black.ignoresSafeArea())`);
  the outer reader no longer does, so `window.safeAreaInsets.top` is the real inset.

## Progress Made
- Landscape (hairline stage, CONTROLS tab) and iPad (stage y 62) were correct on 8e14b3d.

## Current Limitations
- Confirmed by the next iPhone portrait screenshots.

## Artifacts Produced
- `App/UI/RootView.swift`.

## Summary
The outer reader stays inside the safe area and reports the Dynamic Island inset.
