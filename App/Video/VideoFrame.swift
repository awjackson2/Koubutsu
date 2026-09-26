import CoreMedia
import CoreVideo
import KoubutsuCore

/// A video frame as it flows through the app: a `CMSampleBuffer` wrapping a `CVPixelBuffer`, plus timing.
///
/// Wrapping never copies pixels. The same sample buffer is enqueued for display and, when sampled, handed to
/// OCR. `@unchecked Sendable`: the sample buffer and its pixel buffer are immutable once created.
struct VideoFrame: TimedFrame, @unchecked Sendable {
    let sampleBuffer: CMSampleBuffer
    let timing: FrameTiming
    let size: PixelSize

    var pixelBuffer: CVPixelBuffer? { CMSampleBufferGetImageBuffer(sampleBuffer) }

    /// Wraps an existing sample buffer (live capture). Marks it for immediate display.
    init?(sampleBuffer: CMSampleBuffer, timing: FrameTiming) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        Self.markDisplayImmediately(sampleBuffer)
        self.sampleBuffer = sampleBuffer
        self.timing = timing
        self.size = PixelSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
    }

    fileprivate init(sampleBuffer: CMSampleBuffer, timing: FrameTiming, size: PixelSize) {
        self.sampleBuffer = sampleBuffer
        self.timing = timing
        self.size = size
    }

    /// Sets `kCMSampleAttachmentKey_DisplayImmediately` so the display layer shows the frame on arrival
    /// instead of scheduling it against a timebase. This is what keeps display latency minimal.
    static func markDisplayImmediately(_ sampleBuffer: CMSampleBuffer) {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
              CFArrayGetCount(attachments) > 0 else { return }
        let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(dict,
                             Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                             Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
    }
}

/// Builds `VideoFrame`s from pixel buffers (prerecorded sources), caching the format description.
/// Not thread-safe; owned by one source's delivery queue.
struct VideoFrameFactory {
    private var formatDescription: CMVideoFormatDescription?

    mutating func makeFrame(pixelBuffer: CVPixelBuffer, presentationTime: CMTime, timing: FrameTiming) -> VideoFrame? {
        if formatDescription == nil
            || !CMVideoFormatDescriptionMatchesImageBuffer(formatDescription!, imageBuffer: pixelBuffer) {
            var description: CMVideoFormatDescription?
            let status = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &description)
            guard status == noErr, let description else { return nil }
            formatDescription = description
        }
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime,
                                            decodeTimeStamp: .invalid)
        var sampleBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: formatDescription!,
            sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        guard status == noErr, let sampleBuffer else { return nil }
        VideoFrame.markDisplayImmediately(sampleBuffer)
        return VideoFrame(sampleBuffer: sampleBuffer, timing: timing,
                          size: PixelSize(width: CVPixelBufferGetWidth(pixelBuffer),
                                          height: CVPixelBufferGetHeight(pixelBuffer)))
    }
}

/// Pixel buffer attributes shared by all sources: bi-planar 4:2:0 video range, IOSurface-backed.
/// This is what UVC devices typically deliver and what both the display layer and Vision accept natively.
enum VideoPixelFormat {
    static let fourCC: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange

    static var bufferAttributes: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: fourCC,
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
        ]
    }
}
