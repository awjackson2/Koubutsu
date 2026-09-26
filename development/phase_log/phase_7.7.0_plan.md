# Phase 7.7.0 Plan — Unsigned iPad IPA from CI

## Phase
- **Number:** 7.7.0
- **Name:** Unsigned iPad IPA from CI
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
The owner develops on Linux and cannot build for a device locally. CI must produce an installable-after-signing iPad build so the app can be sideloaded (Linux: AltServer-Linux / zsign + ideviceinstaller).

## Immediate Goal
1. `Tools/build_unsigned_ipa.sh`: Release build for `generic/platform=iOS` with signing disabled, packaged as `Payload/Koubutsu.app` → `Koubutsu.ipa`; build number = CI run number.
2. `.github/workflows/ipa.yml`: runs on pushes to main and claude/** and on dispatch; uploads `Koubutsu-ipa` artifact (30 days).
3. `docs/install.md`: Linux sideload and TestFlight install/update guide.

## Scope For This Phase
### In
- Script, workflow, install doc
### Out
- Signing in CI and TestFlight upload (needs a paid developer account and secrets)

## Test Plan
The workflow run produces the artifact; bundle id and build number printed in the log.

## Key Decisions
- Unsigned output: signing happens on the owner's machine with their Apple ID; no credentials in CI.

## Expected Limitations At End Of Phase
- Free Apple ID signatures expire after 7 days.

## What Comes Next
- Optional TestFlight pipeline once a paid account exists.

## Summary
Every push yields a downloadable iPad build ready to sign and sideload.
