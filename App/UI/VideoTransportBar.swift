import KoubutsuCore
import SwiftUI

/// Video mode transport: play/pause, ±10 s, scrubber, loop, transcript, import. File sources only.
struct VideoTransportBar: View {
    let model: AppModel
    @Binding var showingImporter: Bool
    @Binding var showingTranscript: Bool
    @State private var scrubbing = false
    @State private var scrubTime: Double = 0

    var body: some View {
        if let status = model.playback {
            HStack(spacing: 14) {
                Button { Task { await model.skip(by: -10) } } label: { Image(systemName: "gobackward.10") }
                Button { Task { await model.togglePlayPause() } } label: {
                    Image(systemName: status.isPlaying ? "pause.fill" : "play.fill").frame(width: 22)
                }
                Button { Task { await model.skip(by: 10) } } label: { Image(systemName: "goforward.10") }
                Text(MediaTimeFormat.clock(scrubbing ? scrubTime : status.currentTime))
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 44, alignment: .trailing)
                Slider(
                    value: Binding(
                        get: { scrubbing ? scrubTime : status.currentTime },
                        set: { scrubTime = $0 }),
                    in: 0...max(status.duration, 0.1),
                    onEditingChanged: { editing in
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
                    })
                Text(MediaTimeFormat.clock(status.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button { Task { await model.setLooping(!status.loops) } } label: {
                    Image(systemName: status.loops ? "repeat.circle.fill" : "repeat.circle")
                }
                Button { showingTranscript = true } label: { Image(systemName: "text.bubble") }
                Button { showingImporter = true } label: { Image(systemName: "square.and.arrow.down") }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(white: 0.1))
        }
    }
}
