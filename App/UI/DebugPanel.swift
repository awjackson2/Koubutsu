import KoubutsuCore
import SwiftUI

/// Developer diagnostics: source, format, frame flow. Extended by later phases (OCR, translation, cache).
struct DebugPanel: View {
    let model: AppModel

    var body: some View {
        let m = model.metrics
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 2) {
            row("Source", model.sourceKind?.displayName ?? "—", model.selection?.label ?? "")
            row("Format", model.format.map { "\($0.size) \($0.pixelFormatString)" } ?? "—",
                model.format.map { String(format: "%.2f fps nominal", $0.nominalFrameRate) } ?? "")
            row("Frames", String(format: "in %.1f  shown %.1f  sampled %.1f fps", m.framesReceivedPerSecond,
                                 m.framesDisplayedPerSecond, m.framesSampledPerSecond),
                "total \(m.totalFramesReceived)")
            if let t = m.lastFrameTiming {
                row("Last frame", "#\(t.sequence)  pts \(t.presentationTime)",
                    String(format: "age %.0f ms", max(0, model.clock.now() - t.hostTime) * 1000))
            }
            let perf = model.performance.snapshot
            row("Device", String(format: "CPU %.0f%%  mem %.0f MB", perf.cpuPercent, perf.memoryMB),
                "thermal \(model.performance.thermalLabel)\(perf.lowPowerMode ? "  low power" : "")"
                    + "  display dropped \(perf.displayDroppedFrames)/\(perf.displayTotalFrames)")
            row("Audio", audioLabel, model.captureDevices.devices.map(\.name).joined(separator: ", "))
            row("OCR", String(format: "%.0f fps target  %.1f fps done", model.settings.ocrRate.rawValue,
                              m.ocrProcessedPerSecond),
                "dropped \(m.ocrDroppedFrames)  failed \(m.ocrFailures)\(m.ocrInFlight ? "  ●" : "")")
            row("OCR latency", latency(m.ocrLatency), "capture→OCR " + latency(m.captureToOCRLatency))
            row("Translation", model.translation.providerName, availabilityLabel)
            row("Transl. latency", latency(m.translationLatency), "capture→EN " + latency(m.captureToTranslationLatency))
            row("Shown", "capture→shown " + latency(m.captureToDisplayLatency),
                "requests \(m.translationRequests)  failed \(m.translationFailures)")
            row("Cache", "hit \(m.translationCacheHits)  miss \(m.translationCacheMisses)",
                m.translationCacheHitRate.map { String(format: "hit rate %.0f%%  dup text %d", $0 * 100, m.duplicateTextDetections) }
                    ?? "dup text \(m.duplicateTextDetections)")
        }
        .font(.caption.monospaced())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        HStack(alignment: .top) {
            Button(model.isBenchmarking ? "Benchmarking…" : "Run benchmark") {
                Task { await model.runBenchmark() }
            }
            .disabled(model.isBenchmarking)
            .font(.caption)
            if let report = model.benchmarkReport {
                Text(report).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var audioLabel: String {
        switch model.captureAudio.state {
        case .stopped: model.selection?.isCapture == true ? "capture audio off" : "test video audio"
        case .running(let input): String(format: "%@ level %.2f", input, model.captureAudio.level)
        case .unavailable(let reason): reason
        }
    }

    private var availabilityLabel: String {
        switch model.translation.availability {
        case .installed: "installed"
        case .needsDownload: "needs download"
        case .unsupported: "unsupported"
        case .unknown(let reason): "unknown: \(reason)"
        case nil: "checking…"
        }
    }

    private func latency(_ s: LatencySummary) -> String {
        guard let last = s.last else { return "—" }
        return String(format: "%.0f ms (p50 %.0f, p95 %.0f)", last * 1000, (s.p50 ?? 0) * 1000, (s.p95 ?? 0) * 1000)
    }

    private func row(_ title: String, _ value: String, _ detail: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value)
            Text(detail).foregroundStyle(.secondary)
        }
    }
}
