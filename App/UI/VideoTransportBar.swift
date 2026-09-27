import KoubutsuCore
import SwiftUI

/// Video mode transport, VCR style: ◀◀ ▶/‖ ▶▶, a time counter, a tick scrubber, loop and import.
/// File sources only; the video otherwise runs through exactly the same live pipeline as a capture device.
/// Compact (10.2.0): no ruler ticks, duration, loop or import (loop is in the control bar's More menu, import in the
/// source menu).
struct VideoTransportBar: View {
    let model: AppModel
    @Binding var showingImporter: Bool
    @State private var scrubbing = false
    @State private var scrubTime: Double = 0
    @Environment(\.layoutClass) private var layoutClass

    /// Skip step of the ◀◀ / ▶▶ buttons and of the VoiceOver scrubber adjustment.
    private static let skipSeconds: Double = 10

    var body: some View {
        if let status = model.playback {
            let compact = layoutClass.isCompact
            HStack(spacing: compact ? 2 : 6) {
                Button { Task { await model.skip(by: -Self.skipSeconds) } } label: { KIconLabel(icon: "rewind") }
                    .buttonStyle(KIconButtonStyle())
                    .accessibilityLabel("Back 10 seconds")
                Button { Task { await model.togglePlayPause() } } label: {
                    KIconLabel(icon: status.isPlaying ? "pause" : "play")
                }
                .buttonStyle(KIconButtonStyle(active: !status.isPlaying))
                .accessibilityLabel(status.isPlaying ? pauseTitle : playTitle)
                Button { Task { await model.skip(by: Self.skipSeconds) } } label: { KIconLabel(icon: "forward") }
                    .buttonStyle(KIconButtonStyle())
                    .accessibilityLabel("Forward 10 seconds")
                Text(MediaTimeFormat.clock(scrubbing ? scrubTime : status.currentTime))
                    .font(K.osd(compact ? 16 : 18))
                    .monospacedDigit()
                    .frame(minWidth: compact ? 48 : 64, alignment: .trailing)
                    .accessibilityHidden(true)
                Scrubber(value: Binding(get: { scrubbing ? scrubTime : status.currentTime }, set: { scrubTime = $0 }),
                         duration: max(status.duration, 0.1), showsTicks: !compact) { editing in
                    if editing {
                        scrubTime = status.currentTime
                        scrubbing = true
                    } else {
                        // Seek once on release; seeking while dragging would flood the player.
                        let target = scrubTime
                        Task {
                            await model.seek(to: target)
                            scrubbing = false
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Position")
                .accessibilityValue(positionValue(status))
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: Task { await model.skip(by: Self.skipSeconds) }
                    case .decrement: Task { await model.skip(by: -Self.skipSeconds) }
                    @unknown default: break
                    }
                }
                if !compact {
                    Text(MediaTimeFormat.clock(status.duration))
                        .font(K.osd(14))
                        .foregroundStyle(K.paper.opacity(0.55))
                        .accessibilityHidden(true)
                    Button { Task { await model.setLooping(!status.loops) } } label: { KIconLabel(icon: "loop") }
                        .buttonStyle(KIconButtonStyle(active: status.loops))
                        .accessibilityLabel("Loop")
                        .accessibilityValue(status.loops ? onValue : offValue)
                    Button { showingImporter = true } label: { KIconLabel(icon: "import") }
                        .buttonStyle(KIconButtonStyle())
                        .accessibilityLabel("Import video")
                }
            }
            .padding(.horizontal, compact ? 8 : 12)
            // 44 pt targets without extra padding keep the bar as tall as before (36 pt buttons + 4 pt padding).
            .kSurface(.ink)
            .overlay(alignment: .top) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
        }
    }

    private var playTitle: String { "Play" }
    private var pauseTitle: String { "Pause" }
    private var onValue: String { "On" }
    private var offValue: String { "Off" }

    /// "1:05 of 3:20" for VoiceOver.
    private func positionValue(_ status: PlaybackStatus) -> String {
        let current = MediaTimeFormat.clock(scrubbing ? scrubTime : status.currentTime)
        return "\(current) of \(MediaTimeFormat.clock(status.duration))"
    }
}

/// Tape-counter scrubber: tick ruler (regular only), red progress, square head.
private struct Scrubber: View {
    @Binding var value: Double
    let duration: Double
    var showsTicks = true
    let onEditingChanged: (Bool) -> Void
    @State private var dragging = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fraction = min(1, max(0, value / duration))
            ZStack(alignment: .leading) {
                if showsTicks {
                    HStack(spacing: 0) {
                        ForEach(0...40, id: \.self) { i in
                            Rectangle().fill(K.paper.opacity(0.35)).frame(width: 1, height: i % 10 == 0 ? 12 : 5)
                            if i < 40 { Spacer(minLength: 0) }
                        }
                    }
                }
                Rectangle().fill(K.paper.opacity(0.3)).frame(height: 2)
                Rectangle().fill(K.red).frame(width: width * fraction, height: 4)
                Rectangle().fill(K.red)
                    .overlay(Rectangle().stroke(K.paper, lineWidth: 2))
                    .frame(width: 14, height: 20)
                    .offset(x: max(0, min(width - 14, width * fraction - 7)))
            }
            .frame(height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    if !dragging {
                        dragging = true
                        onEditingChanged(true)
                    }
                    value = min(1, max(0, drag.location.x / max(width, 1))) * duration
                }
                .onEnded { _ in
                    dragging = false
                    onEditingChanged(false)
                })
        }
        // As tall as the 44 pt buttons, so the whole bar height is a drag target.
        .frame(height: KIconButtonStyle.minimumTarget)
    }
}
