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
            row("OCR tap", String(format: "%.0f fps target", model.settings.ocrRate.rawValue),
                "dropped \(m.ocrDroppedFrames)")
        }
        .font(.caption.monospaced())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ title: String, _ value: String, _ detail: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value)
            Text(detail).foregroundStyle(.secondary)
        }
    }
}
