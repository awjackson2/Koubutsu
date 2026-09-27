# Phase 9.4.2 Log — Screenshot suite on demand

## Phase
- **Number:** 9.4.2
- **Name:** Screenshot suite on demand
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch, CI tooling): the screenshot workflow ran on every push, took 40–70 min on a macOS runner, was never
cancelled by later pushes and asserted nothing. Its output was only read for UI phases.

## Major Additions
- `series` workflow input: comma-separated configuration names; `Tools/ci_screenshots.sh` skips the others
  (`SERIES` environment variable; empty runs all nine).

## Major Changes
- `screenshots.yml` trigger: `push` removed, `workflow_dispatch` only.

## Progress Made
- Filter logic checked locally (empty, `study,card`, spaces around names).

## Key Decisions
- Build, tests, IPA and core Linux workflows keep running on every push; they are the checks.
- The build step still runs in full for a filtered run; the saving is the ~110 s per skipped configuration plus
  its Vision warm-up.

## Current Limitations
- A filtered dispatch has not yet been run on CI.

## Artifacts Produced
- `.github/workflows/screenshots.yml`, `Tools/ci_screenshots.sh`, `README.md`.

## What Comes Next
- Dispatch the screenshot workflow manually when a phase changes the UI.

## Summary
Screenshots are captured on request, optionally for a subset of screens, instead of on every push.
