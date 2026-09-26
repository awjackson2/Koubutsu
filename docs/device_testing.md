# Device Testing Procedures

Last synced: Phase 4.3.0 (2026-09-26)

These procedures need hardware this project's CI cannot provide. Each step lists what to record so results
can be written into a phase log.

## 1. Install on a physical iPad (prerecorded video)

Requirements: a Mac with Xcode 26.x, an Apple ID (free provisioning works), a USB-C iPad on iPadOS 26+.

1. Open `Koubutsu.xcodeproj`. Select the `Koubutsu` target → Signing & Capabilities → choose your team
   (the project uses automatic signing; bundle ID `com.awjackson2.Koubutsu` may need a unique suffix).
2. Select the iPad as run destination and press Run.
3. The app starts the bundled synthetic clip. To test real footage: Files app → drag an MP4 into
   *On My iPad → Koubutsu*, or use the source menu → *Import video…*. Footage never leaves the device.
4. Translation needs the Japanese→English model: tap **Download** in the panel when prompted
   (Settings → Apps → Translate can also manage languages).

Record (debug panel, after 2 minutes of playback):
- in / shown FPS (target: shown ≈ source rate, 59.94–60)
- OCR fps done, OCR latency p50/p95, capture→OCR p95
- translation latency p50/p95, capture→shown p95, cache hit rate
- CPU %, memory MB, thermal state, display dropped frames

## 2. In-app benchmark on device

Debug panel → **Run benchmark**. The report (exact-match rate, character accuracy, per-checkpoint detection
latency, mean OCR time) appears in the panel and in the device log (`com.awjackson2.Koubutsu`, category
`Benchmark`). Compare against the simulator CI numbers printed by `OCRBenchmarkTests`.

## 3. Sustained run (thermal / battery)

Loop real footage for 30 minutes at OCR 5 FPS, then 30 minutes at 10 FPS. Record CPU, thermal state
progression, battery drop (%), and any FPS degradation.

## 4. Capture hardware (CC19L or equivalent) — product plan §35

Connection: Switch 2 → USB-C → capture adapter (PD power connected) → USB-C → iPad.

| # | Check | How |
|---|---|---|
| 1 | Switch 2 enters external display mode | Switch screen turns off / shows output |
| 2 | iPadOS recognizes the device | Source menu lists "<name> (USB capture)"; debug panel "Audio" row lists devices |
| 3 | AVFoundation exposes UVC video | Selecting it shows video; state `running` |
| 4 | Formats | Debug "Format" row shows chosen size/fps/pixel format (selector prefers 1920×1080 @ 60, 420v) |
| 5 | 1080p60 achieved | "in" FPS ≈ 60 |
| 6 | Audio input appears | Debug "Audio" row shows the USB input and a moving level |
| 7 | Video + audio together | Both rows active simultaneously |
| 8 | 60 FPS rendering | "shown" FPS ≈ 60, display dropped frames not increasing |
| 9 | Capture→display latency | See §5 |
| 10 | OCR on live capture | Japanese dialogue appears in the panel/overlay |
| 11 | Thermal | 30-minute session, record thermal state |
| 12 | Stability | Unplug/replug the adapter: error shown, capture resumes on reconnect |

## 5. Glass-to-glass latency (§36)

Film the Switch's own screen output path and the iPad side by side with a 240 FPS camera (phone slo-mo):
1. Use a game action with an instant visual change (menu cursor move) and film the controller + iPad.
2. Count frames between the input/visual change on a reference display (TV through the dock, or the
   Switch handheld screen before undocking) and the iPad showing it.
3. Latency = frames ÷ 240 s. Repeat 10 times; record median and max.
Do not assume 16.7 ms: capture adapters buffer internally.
