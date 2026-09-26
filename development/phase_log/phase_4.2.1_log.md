# Phase 4.2.1 Log — Benchmark report as test attachment

## Phase
- **Number:** 4.2.1
- **Name:** Benchmark report as test attachment
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Make benchmark numbers visible in CI, not just pass/fail.

## Major Additions
- `Attachment.record` of the report
- CI step exporting xcresult attachments

## Major Changes
- None

## Progress Made
- CI run 18 printed the first report: exact 92 %, char accuracy 95 %.

## Key Decisions
- None

## Current Limitations
- None

## Artifacts Produced
- AppTests/OCRBenchmarkTests.swift
- .github/workflows/ios.yml

## What Comes Next
- 4.2.2.

## Summary
Benchmark numbers are recorded on every CI run.
