import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

/// §33 regression benchmark: real Vision OCR over the synthetic clip, scored against its manifest.
@Suite(.serialized, .timeLimit(.minutes(20)))
struct OCRBenchmarkTests {
    @Test func syntheticClipBenchmark() async throws {
        let manifest = try ClipManifest.load(named: MediaLibrary.defaultClipName)
        let clip = try #require(MediaLibrary.defaultItem?.url)
        // 0.5 FPS keeps the simulator run (CPU-only Vision, tens of seconds per 1080p frame) within CI
        // limits while still sampling every checkpoint; on device use the in-app benchmark at 2 FPS.
        let report = try await BenchmarkRunner(sampleRate: 0.5).run(clip: clip, manifest: manifest)
        print("OCR BENCHMARK\n" + report.summary)
        #expect(report.sampleCount >= 12)
        #expect(report.exactMatchRate >= 0.8, "\(report.summary)")
        #expect(report.meanCharacterAccuracy >= 0.9, "\(report.summary)")
    }
}
