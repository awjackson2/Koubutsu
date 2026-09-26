# Phase 1.5.1 Log — Vision OCR fixture tests on CI

## Phase
- **Number:** 1.5.1
- **Name:** Vision OCR fixture tests on CI
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Prove OCR text and geometry on real decoded frames of the committed clip.

## Major Additions
- `AppTests/ClipFrameReader.swift` (AVAssetReader frame at time t; system-font rendered text frame).
- `App/Platform/ClipManifest.swift`.
- `AppTests/OCRFixtureTests.swift`.

## Major Changes
- Diagnosed apparent CI hangs: none — simulator OCR is slow and the host app ran its own OCR concurrently. The app now skips its pipeline when hosting tests; OCR suites have 10–20 min limits; CI gained a watchdog (`Tools/ci_simulator_test.sh`) and job logs are fetched by URL.

## Progress Made
- CI run 13: dialogue lines recognized with box IoU ≥ 0.5 vs manifest; ROI (dialogue region) results map back to full-frame coordinates; title and katakana menu items recognized; system-font 「鍵が必要です」 recognized. Fixture OCR takes 0.7–3.5 s per 1080p frame on the simulator once warm.

## Key Decisions
- Tests compare whitespace-squashed text and require the core kana/kanji sequence.

## Current Limitations
- Synthetic text is cleaner than real game footage.

## Artifacts Produced
- AppTests/OCRFixtureTests.swift
- AppTests/ClipFrameReader.swift
- App/Platform/ClipManifest.swift
- Tools/ci_simulator_test.sh

## What Comes Next
- Major 2.

## Summary
OCR correctness — text and geometry, including ROI mapping — is locked in by CI tests on decoded video.
