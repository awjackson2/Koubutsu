import KoubutsuCore
import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @State private var model = AppModel()
    @State private var showingImporter = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            VideoDisplayView(renderer: model.renderer)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .overlay(alignment: .center) { sourceMessage }
            RecognizedTextPanel(result: model.latestOCR, status: model.ocrStatus)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(minHeight: 120, alignment: .top)
                .background(Color(white: 0.05))
            if model.settings.showDebugStatistics {
                DebugPanel(model: model)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.08))
            }
            ControlBar(model: model, showingImporter: $showingImporter)
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie]) { result in
            if case .success(let url) = result {
                Task { await model.importVideo(from: url) }
            }
        }
        .task { await model.start() }
        .onChange(of: scenePhase) { _, phase in
            Task { await model.scenePhaseChanged(phase) }
        }
    }

    @ViewBuilder private var sourceMessage: some View {
        if let message = model.errorMessage {
            Text(message)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ControlBar: View {
    let model: AppModel
    @Binding var showingImporter: Bool

    var body: some View {
        HStack(spacing: 16) {
            Menu {
                ForEach(model.mediaItems) { item in
                    Button(item.origin == .bundled ? "\(item.name) (bundled)" : item.name) {
                        Task { await model.select(.media(item)) }
                    }
                }
                Divider()
                Button("USB capture device") { Task { await model.select(.uvc) } }
                Divider()
                Button("Import video…") { showingImporter = true }
            } label: {
                Label(model.selection?.label ?? "Select source", systemImage: "play.rectangle")
            }
            Button {
                Task { model.isRunning ? await model.stop() : await model.start() }
            } label: {
                Image(systemName: model.isRunning ? "stop.fill" : "play.fill")
            }
            Spacer()
            Text(statusText)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var statusText: String {
        let m = model.metrics
        let size = model.format.map { "\($0.size)" } ?? "—"
        return String(format: "%@ · %@ · in %.1f fps · shown %.1f fps", stateLabel, size,
                      m.framesReceivedPerSecond, m.framesDisplayedPerSecond)
    }

    private var stateLabel: String {
        switch model.sourceState {
        case .idle: "idle"
        case .starting: "starting"
        case .running: "running"
        case .stopped: "stopped"
        case .failed: "failed"
        }
    }
}
