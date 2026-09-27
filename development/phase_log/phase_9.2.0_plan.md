# Phase 9.2.0 Plan — Retheme every screen

## Phase
- **Number:** 9.2.0
- **Name:** Apply the Koubutsu components to every screen
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Replace stock controls, SF Symbols, system menus/forms/navigation bars with the 9.1.0 kit (umbrella 9.0.0).

## Immediate Goal
1. Ink side (around the video): control bar (logo mark, KMenu source/view menus, pixel icon buttons, words badge,
   blinking VCR status), transport bar (◀◀ ▶ ▶▶, tape-counter scrubber), translation/recognized/debug panels,
   replacement boxes (VCR type, ink, red tick), furigana labels (DotGothic16), study view (red HUD ticks, square
   loupe, "▮▮ PAUSE" readout), study panel.
2. Paper side (sheets): word card, word bank (search field, row actions instead of swipes), review, settings
   (numbered spec sheet with KToggle/KSegmented/KSlider), recent lines — all with `KSheetHeader`, no
   `NavigationStack`, square corners, grain.

## Confirmed Starting Point
9.1.0 (`6bd3301`).

## Scope For This Phase
### In
- `App/UI/*` restyling; behaviour unchanged.
### Out
- Animations beyond press feedback (9.3.0).

## Test Plan
CI iOS build/tests; screenshots of every screen (existing series + settings/bank/review series).

## Summary
Every screen speaks Koubutsu.
