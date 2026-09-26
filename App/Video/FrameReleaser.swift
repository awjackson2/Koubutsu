import Dispatch

/// Releases frames off the delivery path.
///
/// Dropping the last reference to a pooled `CVPixelBuffer` can run CoreVideo pool maintenance that makes a
/// synchronous IOSurface IPC call. On the frame-delivery thread that both stalls the display path and — in
/// CI run 14 — overflowed the dispatch worker's stack. Displaced frames are handed here instead.
enum FrameReleaser {
    private static let queue = DispatchQueue(label: "koubutsu.video.release", qos: .utility)

    static func release(_ frame: VideoFrame) {
        queue.async { withExtendedLifetime(frame) {} }
    }
}
