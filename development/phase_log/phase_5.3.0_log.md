# Phase 5.3.0 Log — Device monitor, picker, hot-plug

## Phase
- **Number:** 5.3.0
- **Name:** Device monitor, picker, hot-plug
- **Status:** Completed (unverified on hardware)
- **Date completed:** 2026-09-26

## Phase Goal
Automatic device discovery, switching and reconnection.

## Major Additions
- `CaptureDeviceMonitor`
- source menu device list
- auto-switch + disconnect/reconnect handling in `AppModel`
- capture settings

## Major Changes
- None

## Progress Made
- Compiles and runs in CI (no devices).

## Key Decisions
- None

## Current Limitations
- Hot-plug behaviour unverified without hardware.

## Artifacts Produced
- App/Capture/CaptureDeviceMonitor.swift
- App/AppModel.swift

## What Comes Next
- Major 6.

## Summary
Plugging in a capture device switches the app to it.
