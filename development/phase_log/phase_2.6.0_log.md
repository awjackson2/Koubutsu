# Phase 2.6.0 Log — Settings UI and persistence

## Phase
- **Number:** 2.6.0
- **Name:** Settings UI and persistence
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Growable settings persisted and applied live.

## Major Additions
- `SettingsStore`
- `SettingsView` (OCR rate/quality, ROI, translation mode, display mode, toggles, capture/audio, loop)
- `LaunchOptions` for automation

## Major Changes
- None

## Progress Made
- Compiles and runs in CI; decoding tolerance covered by core tests.

## Key Decisions
- None

## Current Limitations
- Language pair fixed ja→en.

## Artifacts Produced
- App/Platform/SettingsStore.swift
- App/UI/SettingsView.swift

## What Comes Next
- 2.7.0.

## Summary
Settings are adjustable and persistent.
