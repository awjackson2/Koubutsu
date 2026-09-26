import AVFoundation
import KoubutsuCore

/// Runs OCR over a clip offline (decode → sample → recognize) and scores it against the clip's manifest.
/// Used by the CI benchmark test and by the in-app "Run benchmark" action on a physical iPad.
struct BenchmarkRunner {
    var service = VisionOCRService()
    var configuration = OCRConfiguration.japanese
    /// OCR samples per second of clip time.
    var sampleRate: Double = 2

    func run(clip url: URL, manifest: ClipManifest) async throws -> BenchmarkReport {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoSourceError.unsupportedFormat("no video track")
        }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: VideoPixelFormat.bufferAttributes)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else {
            throw VideoSourceError.mediaUnreadable(reader.error?.localizedDescription ?? "reader failed")
        }
        var samples: [BenchmarkSample] = []
        var nextTime = 0.0
        var sequence: UInt64 = 0
        let clock = AppleHostClock()
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            guard pts.seconds + 1e-6 >= nextTime else { continue }
            nextTime += 1 / sampleRate
            let timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(pts), hostTime: clock.now(),
                                     sourceSessionID: 0)
            sequence += 1
            guard let frame = VideoFrame(sampleBuffer: sampleBuffer, timing: timing) else { continue }
            let result = try await service.recognize(frame, configuration: configuration)
            samples.append(BenchmarkSample(time: pts.seconds, recognized: result.observations.map(\.text),
                                           ocrDuration: result.recognitionDuration))
        }
        reader.cancelReading()
        let checkpoints = manifest.checkpoints.map {
            BenchmarkCheckpoint(id: $0.id, start: $0.start, end: $0.end, expected: $0.expected.map(\.text))
        }
        return OCRBenchmark.evaluate(checkpoints: checkpoints, samples: samples)
    }
}
