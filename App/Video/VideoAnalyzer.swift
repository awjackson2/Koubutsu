import AVFoundation
import KoubutsuCore
import Synchronization

/// Runs the OCR → stabilization → transcript pipeline over a whole video file faster than real time
/// (decode, sample, recognize; no display). Used by Video mode's "Analyze video" and by the footage test.
struct VideoAnalyzer {
    struct Report: Sendable {
        var transcript: TranscriptBuilder
        var sampledFrames: Int
        var framesWithText: Int
        var meanOCRDuration: Double
        var videoDuration: Double
        var elapsed: Double

        var summary: String {
            """
            video: \(MediaTimeFormat.clock(videoDuration)), sampled frames: \(sampledFrames), with text: \(framesWithText)
            mean OCR: \(Int(meanOCRDuration * 1000)) ms, analysis time: \(MediaTimeFormat.clock(elapsed))
            stable dialogue lines: \(transcript.entries.count)
            """
        }
    }

    var service = VisionOCRService()
    var configuration = OCRConfiguration.japanese
    /// OCR samples per second of video.
    var sampleRate: Double = 2

    /// - Parameter progress: called with 0...1 on an arbitrary thread.
    func analyze(url: URL, progress: (@Sendable (Double) -> Void)? = nil) async throws -> Report {
        let started = Date()
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoSourceError.unsupportedFormat("no video track")
        }
        let duration = try await asset.load(.duration).seconds
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: VideoPixelFormat.bufferAttributes)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else {
            throw VideoSourceError.mediaUnreadable(reader.error?.localizedDescription ?? "reader failed")
        }
        var stabilizer = TextStabilizer()
        var transcript = TranscriptBuilder()
        var nextTime = 0.0, sequence: UInt64 = 0, sampled = 0, withText = 0, ocrTotal = 0.0
        while let sampleBuffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            guard pts.seconds + 1e-6 >= nextTime else { continue }
            nextTime += 1 / sampleRate
            // Media time doubles as host time: stabilization windows then run on the video's clock.
            let timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(pts),
                                     hostTime: HostTime(seconds: pts.seconds), sourceSessionID: 0)
            sequence += 1
            guard let frame = VideoFrame(sampleBuffer: sampleBuffer, timing: timing) else { continue }
            let result = try await service.recognize(frame, configuration: configuration)
            sampled += 1
            ocrTotal += result.recognitionDuration
            if !result.observations.isEmpty { withText += 1 }
            for event in stabilizer.process(result) {
                switch event {
                case .stabilized(let stable): transcript.stabilized(stable)
                case .removed(let id), .invalidated(let id): transcript.ended(trackID: id, at: pts.seconds)
                }
            }
            if duration > 0 { progress?(min(pts.seconds / duration, 1)) }
        }
        reader.cancelReading()
        return Report(transcript: transcript, sampledFrames: sampled, framesWithText: withText,
                      meanOCRDuration: sampled > 0 ? ocrTotal / Double(sampled) : 0, videoDuration: duration,
                      elapsed: Date().timeIntervalSince(started))
    }
}

/// Thread-safe progress value written from the analyzer.
final class ProgressBox: Sendable {
    private let storage = Synchronization.Mutex<Double>(0)
    var value: Double {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }
}
