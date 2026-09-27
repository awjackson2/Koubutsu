# Phase 9.2.0 Log — Retheme every screen

## Phase
- **Number:** 9.2.0
- **Name:** Apply the Koubutsu components to every screen
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_9.2.0_plan.md` (umbrella 9.0.0).

## Major Additions
- Launch options `--open=settings|words|review|recent` and `--seed-words` (demo word bank) and screenshot series
  for settings, word bank and review.

## Major Changes
- Ink side: control bar (logo mark, `KMenu` source/view menus, pixel icon buttons, pulsing due badge, blinking OSD
  status), transport bar (pixel transport icons, tape-counter scrubber), translation/recognized/debug panels,
  replacement boxes (VCR type on ink, red tick), furigana in DotGothic16, study view (red HUD ticks, square loupe,
  "▮▮ PAUSE" readout), study panel.
- Paper side: word card, word bank (search field, row actions), review, settings (numbered spec sheet with
  `KToggle`/`KSegmented`/`KSlider`), recent lines — `KSheetHeader` instead of navigation bars, square grained sheets.
- `KSegmented` options built with `map` (a tuple-array literal did not type-check).

## Progress Made
- CI IPA green on `96e9e33`; iOS tests verified on the Major 9 head (`024312b`).

## Key Decisions
- Behaviour unchanged; only presentation.

## Current Limitations
- System file importer, share sheet and the iPadOS dictionary stay system UI.

## Artifacts Produced
- `App/UI/*` restyled; `Tools/ci_screenshots.sh` series; `App/Study/WordBankStore.swift` (`seedDemo`).

## What Comes Next
- 9.3.0.

## Summary
Every screen the user touches is built from Koubutsu components.
