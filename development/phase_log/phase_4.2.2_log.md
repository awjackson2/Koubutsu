# Phase 4.2.2 Log — Benchmark scoring matches the pipeline

## Phase
- **Number:** 4.2.2
- **Name:** Benchmark scoring matches the pipeline
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Score what the app translates; fold OCR ellipsis variants.

## Major Additions
- fragment-joined lines in `BenchmarkRunner`
- `TextNormalizer.key` folds 「・・」 runs to an ellipsis
- `docs/benchmarks.md`

## Major Changes
- None

## Progress Made
- CI run 20: exact 92 %, char accuracy 99 %; status line 36 % → 91 %.

## Key Decisions
- None

## Current Limitations
- Small text over moving backgrounds still drops 「ー」.

## Artifacts Produced
- App/Performance/BenchmarkRunner.swift
- docs/benchmarks.md

## What Comes Next
- Device benchmark (docs/device_testing.md §2).

## Summary
Benchmark reflects real pipeline quality: 99 % character accuracy on the synthetic clip.
