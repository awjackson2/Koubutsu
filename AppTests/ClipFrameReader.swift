import AVFoundation
import CoreGraphics
import CoreText
import KoubutsuCore
import Testing
@testable import Koubutsu

enum ClipFrameReader {
    /// Decodes the frame displayed at `time` seconds as a `420v` pixel buffer wrapped in a `VideoFrame`.
    static func frame(at time: Double, in url: URL) async throws -> VideoFrame {
        let asset = AVURLAsset(url: url)
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRange(start: CMTime(seconds: time, preferredTimescale: 600),
                                       duration: CMTime(seconds: 0.5, preferredTimescale: 600))
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: VideoPixelFormat.bufferAttributes)
        reader.add(output)
        #expect(reader.startReading())
        let sample = try #require(output.copyNextSampleBuffer())
        let pts = CMSampleBufferGetPresentationTimeStamp(sample)
        let timing = FrameTiming(sequence: 0, presentationTime: MediaTime(pts),
                                 hostTime: AppleHostClock().now(), sourceSessionID: 0)
        reader.cancelReading()
        return try #require(VideoFrame(sampleBuffer: sample, timing: timing))
    }

    /// Renders `text` in black on white into a BGRA pixel buffer using the system Japanese font.
    static func renderedText(_ text: String, width: Int = 1280, height: Int = 360, fontSize: CGFloat = 72) throws -> VideoFrame {
        var buffer: CVPixelBuffer?
        let attrs: [String: any Sendable] = [kCVPixelBufferIOSurfacePropertiesKey as String: [String: any Sendable]()]
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buffer)
        let pixelBuffer = try #require(buffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let context = try #require(CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer), width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let font = CTFontCreateWithName("HiraginoSans-W6" as CFString, fontSize, nil)
        let attributed = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        ])
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: 60, y: CGFloat(height) / 2 - fontSize / 3)
        CTLineDraw(line, context)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        var factory = VideoFrameFactory()
        let timing = FrameTiming(sequence: 0, presentationTime: .zero, hostTime: AppleHostClock().now(), sourceSessionID: 0)
        let frame = factory.makeFrame(pixelBuffer: pixelBuffer, presentationTime: .zero, timing: timing)
        return try #require(frame)
    }
}

func squashed(_ s: String) -> String {
    s.filter { !$0.isWhitespace }
}
