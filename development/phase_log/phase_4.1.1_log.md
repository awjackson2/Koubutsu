# Phase 4.1.1 Log — Release per-thread Mach ports in CPU sampling

## Phase
- **Number:** 4.1.1
- **Name:** Release per-thread Mach ports in CPU sampling
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Fix a Mach port leak in CPU sampling found while investigating the simulator crash.

## Major Additions
- `mach_port_deallocate` for each thread from `task_threads`
- screenshot job: app-alive check per capture, crash-report and error-log collection

## Major Changes
- None

## Progress Made
- Leak fixed; it was not the crash cause (see 1.4.1).

## Key Decisions
- None

## Current Limitations
- None

## Artifacts Produced
- App/Performance/PerformanceMonitor.swift
- Tools/ci_screenshots.sh

## What Comes Next
- 4.2.0.

## Summary
CPU sampling no longer leaks ports; CI now captures crash evidence.
