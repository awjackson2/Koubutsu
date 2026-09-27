import KoubutsuCore
import SwiftUI

/// Video mode transport, VCR style: ◀◀ ▶/‖ ▶▶, a time counter, a tick scrubber, loop and import.
/// File sources only; the video otherwise runs through exactly the same live pipeline as a capture device.
struct VideoTransportBar: View {
    let model: AppModel
    @Binding var showingImporter: Bool
    @State private var scrubbing = false
    @State private var scrubTime: Double = 0

    var body: some View {
        if let status = model.playback {
            HStack(spacing: 6) {
                Button { Task { await model.skip(by: -10) } } label: { PixelIcon("rewind") }
                    .buttonStyle(KIconButtonStyle())
                Button { Task { await model.togglePlayPause() } } label: {
                    PixelIcon(status.isPlaying ? "pause" : "play")
                }
                .buttonStyle(KIconButtonStyle(active: !status.isPlaying))
                Button { Task { await model.skip(by: 10) } } label: { PixelIcon("forward") }
                    .buttonStyle(KIconButtonStyle())
                Text(MediaTimeFormat.clock(scrubbing ? scrubTime : status.currentTime))
                    .font(K.osd(18))
                    .monospacedDigit()
                    .frame(minWidth: 64, alignment: .trailing)
                Scrubber(value: Binding(get: { scrubbing ? scrubTime : status.currentTime }, set: { scrubTime = $0 }),
                         duration: max(status.duration, 0.1)) { editing in
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
                Text(MediaTimeFormat.clock(status.duration))
                    .font(K.osd(14))
                    .foregroundStyle(K.paper.opacity(0.55))
                Button { Task { await model.setLooping(!status.loops) } } label: { PixelIcon("loop") }
                    .buttonStyle(KIconButtonStyle(active: status.loops))
                Button { showingImporter = true } label: { PixelIcon("import") }
                    .buttonStyle(KIconButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .kSurface(.ink)
            .overlay(alignment: .top) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
        }
    }
}

/// Tape-counter scrubber: tick ruler, red progress, square head.
private struct Scrubber: View {
    @Binding var value: Double
    let duration: Double
    let onEditingChanged: (Bool) -> Void
    @State private var dragging = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fraction = min(1, max(0, value / duration))
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0...40, id: \.self) { i in
                        Rectangle().fill(K.paper.opacity(0.35)).frame(width: 1, height: i % 10 == 0 ? 12 : 5)
                        if i < 40 { Spacer(minLength: 0) }
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
        .frame(height: 32)
    }
}
