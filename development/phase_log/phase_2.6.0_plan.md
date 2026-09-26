# Phase 2.6.0 Plan — Settings UI and persistence

## Phase
- **Number:** 2.6.0
- **Name:** Settings UI and persistence
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Expose the growable settings model (§21) and persist it.

## Immediate Goal
1. `SettingsStore` (UserDefaults JSON, tolerant decoding).
2. `SettingsView` sheet: OCR rate/quality, region of interest, translation mode, display mode, JP/EN/boxes/debug toggles, test-video loop.
3. Settings applied live (OCR tap rate, OCR configuration, translation quality).

## Confirmed Starting Point
`AppSettings` from 1.2.0; controls bar in `RootView`.

## Scope For This Phase
### In
- Store, sheet, live application
### Out
- Custom ROI drawing UI (future)

## Recommended Implementation Direction
`AppModel.settings` didSet → `applySettings()`; everything downstream reads from there.

## Technical Plan
`App/Platform/SettingsStore.swift`, `App/UI/SettingsView.swift`, `App/AppModel.swift`, `App/UI/RootView.swift`.

## Test Plan
Core decoding tests (missing/unknown keys) cover persistence compatibility.

## Key Decisions
- JSON blob under a versioned key (`settings.v1`).

## Expected Limitations At End Of Phase
- Language pair fixed to ja→en in UI.

## What Comes Next
- 2.7.0 dialogue history.

## Summary
User-adjustable, persisted settings applied live.
