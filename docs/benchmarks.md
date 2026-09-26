# OCR Benchmark Results

Produced by `AppTests/OCRBenchmarkTests.swift` (`BenchmarkRunner` over the bundled synthetic clip, 0.5 FPS,
Vision accurate, Japanese). CI prints the report under "Test attachments (benchmark report)".

## CI run 18 — iPad Pro 13" (M5) simulator, iOS 26.5, 2026-09-26

Simulator Vision runs on the CPU (no Neural Engine): OCR times are an upper bound, not device numbers.

```
samples: 12, mean OCR: 1709 ms
exact match: 92%, char accuracy: 95%
  [title] ✓ 冒険を始めますか？ → 冒険を始めますか？ (acc 100%, detect 0 ms)
  [title] ✓ はい → はい (acc 100%, detect 0 ms)
  [title] ✓ いいえ → いいえ (acc 100%, detect 0 ms)
  [dialogue_line1] ✓ この先には強い敵がいる。 → この先には強い敵がいる。 (acc 100%, detect 1200 ms)
  [dialogue_line2] ✓ 鍵が必要です → 鍵が必要です (acc 100%, detect 0 ms)
  [saving] ✗ セーブしています… → ています・・ (acc 36%, detect —)
  [menu] ✓ メニュー → メニュー (acc 100%, detect 0 ms)
  [menu] ✓ アイテム → アイテム (acc 100%, detect 0 ms)
  [menu] ✓ そうび → そうび (acc 100%, detect 0 ms)
  [menu] ✓ ステータス → ステータス (acc 100%, detect 0 ms)
  [menu] ✓ セーブ → セーブ (acc 100%, detect 0 ms)
  [menu] ✓ Ａボタンで決定 → Aボタンで決定 (acc 100%, detect 0 ms)
```

Findings → changes (Phase 4.2.2):
- The only miss is small (36 px) text over a moving striped background, which Vision returns in fragments.
  The benchmark now also scores fragment-joined lines (what the pipeline translates).
- 「…」 was read as 「・・」; comparison keys now fold runs of 「・」 into an ellipsis.
- `detect 1200 ms` for line 1 is clip time from full reveal to first exact sample at 0.5 FPS sampling, not OCR latency.

## Device

Pending: run *Debug panel → Run benchmark* on an iPad (`docs/device_testing.md` §2) and add results here.
