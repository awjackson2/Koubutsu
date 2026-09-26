# Phase 5.3.0 Plan — Device monitor, picker, hot-plug

## Phase
- **Number:** 5.3.0
- **Name:** Device monitor, picker, hot-plug
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
§29/§40: the app finds the capture device automatically and survives unplug/replug.

## Immediate Goal
1. `CaptureDeviceMonitor` (connect/disconnect notifications).
2. Source menu lists connected devices; auto-switch on connect (setting); disconnection shown with a reconnect hint; reconnection restarts capture.

## Confirmed Starting Point
5.2.0.

## Scope For This Phase
### In
- Monitor + AppModel lifecycle + menu
### Out
- Multiple simultaneous devices

## Recommended Implementation Direction
All lifecycle transitions stay in `AppModel` (centralized, §29).

## Technical Plan
`App/Capture/CaptureDeviceMonitor.swift`, `App/AppModel.swift`, `App/UI/RootView.swift`, `App/UI/SettingsView.swift`.

## Test Plan
CI compile; behaviour requires hardware.

## Key Decisions
- Auto-switch default on.

## Expected Limitations At End Of Phase
- Unverified on hardware.

## What Comes Next
- Major 6 audio.

## Summary
Plug in the capture adapter and the game appears.
