# Koubutsu — Project Guidance

iPad application that turns an iPad into a real-time translated display for a Nintendo Switch 2
running Japanese games. Video arrives from a UVC/UAC capture device (or a prerecorded test video),
is displayed with minimal latency, and is sampled asynchronously for Vision OCR and translation.

## Non-negotiable engineering rules

1. The display path never waits on OCR or translation. OCR/translation are asynchronous consumers.
2. OCR uses a latest-frame slot, never an unbounded queue. Dropping OCR frames is acceptable; dropping display frames is not.
3. Downstream code never knows which `VideoSource` produced a frame (test video vs UVC).
4. Timestamps (presentation time + host-clock capture time) are preserved end to end.
5. OCR bounding boxes and confidence are preserved; text is never collapsed to one string early.
6. All coordinate conversion goes through the coordinate-mapping layer. No ad hoc geometry in UI code.
7. External services (OCR, translation) sit behind protocols.
8. No third-party runtime dependencies without a documented reason. Apple frameworks first.
9. No video frames or text leave the device by default.
10. Measure before optimizing. Latency instrumentation is a product feature.
11. Do not invent Apple APIs. Verify against the SDK (CI SDK report, `development/design/platform_apis.md`).

## Build environment facts

- Development containers are Linux with no Xcode. Apple-framework code cannot be compiled locally.
- Platform-agnostic logic lives in the `KoubutsuCore` Swift package and must build and test on Linux (`swift test`).
- Apple-framework code is compiled and tested on GitHub Actions macOS runners (repository is public).
- A phase touching Apple-framework code is not verified until the macOS CI job is green.

## Branch policy for this repository

- Agent sessions are restricted to one designated branch per session (e.g. `claude/...`).
  The phase workflow's `phase-<MAJOR.MINOR>-slug` branches are therefore mapped onto that designated branch:
  each phase is one or more `Phase X.Y.Z:` commits on it; PRs are opened only on request.
- The default branch (`main`) is protected by policy. Never push to it directly.

---

## Phase workflow charter

Every meaningful development effort is a numbered phase `MAJOR.MINOR.PATCH` (digits only, never letter suffixes).

- **Major** — milestone. `MAJOR.0.0` is the Major's umbrella/roadmap plan.
- **Minor** — a self-contained feature (one branch / one PR in the standard workflow).
- **Patch** — iteration or fix on a Minor, committed on the same branch.
- Capitalize Major / Minor / Patch when naming phases.

Files under `development/phase_log/`:
- `phase_<NUM>_plan.md` — written before any code, from `phase_plan_template.md`.
- `phase_<NUM>_log.md` — written after the work, from `phase_log_template.md`.
- `phase_index.md` — chronological timeline; append one line per logged phase at the bottom.

Living design docs under `development/design/` are the curated present; phase logs are immutable history.
Sync design docs (with a `Last synced: Phase X.Y.Z` marker) in the same commit as the phase log.

Phase cycle: prompt → discussion → phase number → plan → 🟦 Plan Confirmation → 🟩 Development Approval →
implement → change summary → log → design-doc sync → index append → scoped tests → commit → sync with default branch → 🏁 Phase Done.

Rules:
- Plan before code, always. Never backfill a plan.
- Never silently expand a phase. Out-of-scope work goes to "What Comes Next" or an explicit plan amendment.
- Commit with explicit file lists (never `git add -A`), message `Phase X.Y.Z: <summary>`, `Co-Authored-By:` trailer.
- Run scoped tests locally; the full suite is CI's job.
- Corrective changes are classified with the 🔧 Fix banner as a Patch or as trivial.
- Numbering clusters by theme; leave room to append.

Response banners: 🟦 PLAN CONFIRMATION · 🟩 DEVELOPMENT APPROVAL · 🏁 PHASE DONE · 🔧 FIX
