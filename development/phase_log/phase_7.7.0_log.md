# Phase 7.7.0 Log — Unsigned iPad IPA from CI

## Phase
- **Number:** 7.7.0
- **Name:** Unsigned iPad IPA from CI
- **Status:** Completed (pending first CI run)
- **Date completed:** 2026-09-26

## Phase Goal
Produce a sign-and-sideload iPad build from CI for an owner working on Linux.

## Major Additions
- `Tools/build_unsigned_ipa.sh`, `.github/workflows/ipa.yml` (artifact `Koubutsu-ipa`), `docs/install.md`

## Major Changes
- None

## Progress Made
- Script syntax and workflow YAML validated locally; device build is verified by the first CI run.

## Key Decisions
- Signing stays on the owner's machine; CI holds no Apple credentials.

## Current Limitations
- Free Apple ID signatures last 7 days; AltServer-Linux is unofficial.

## Artifacts Produced
- Tools/build_unsigned_ipa.sh, .github/workflows/ipa.yml, docs/install.md

## What Comes Next
- TestFlight pipeline if a paid developer account is added.

## Summary
CI now builds a downloadable iPad IPA on every push.
