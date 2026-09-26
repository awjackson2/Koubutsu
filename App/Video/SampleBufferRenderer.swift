import AVFoundation
import UIKit

/// The single display path for every video source.
///
/// Owns an `AVSampleBufferDisplayLayer`; frames are enqueued from the source's delivery queue with
/// display-immediately semantics. The layer outlives any SwiftUI view that hosts it.
final class SampleBufferRenderer: @unchecked Sendable {
    /// Main-thread only (layer tree operations).
    @MainActor let layer: AVSampleBufferDisplayLayer
    /// Thread-safe per AVFoundation; used from the delivery queue.
    private let videoRenderer: AVSampleBufferVideoRenderer

    @MainActor
    init() {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = UIColor.black.cgColor
        self.layer = layer
        self.videoRenderer = layer.sampleBufferRenderer
    }

    /// Enqueue for immediate display. Never blocks on downstream work.
    func enqueue(_ frame: VideoFrame) {
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            videoRenderer.flush()
        }
        videoRenderer.enqueue(frame.sampleBuffer)
    }

    /// Clears the displayed image (source stopped or switched).
    func clear() {
        videoRenderer.flush(removingDisplayedImage: true, completionHandler: nil)
    }
}
