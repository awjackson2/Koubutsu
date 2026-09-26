import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

/// §33 regression benchmark: real Vision OCR over the synthetic clip, scored against its manifest.
@Suite(.serialized, .timeLimit(.minutes(6)))
struct OCRBenchmarkTests {
    @Test func syntheticClipBenchmark() async throws {
        let manifest = try ClipManifest.load(named: MediaLibrary.defaultClipName)
        let clip = try #require(MediaLibrary.defaultItem?.url)
        let report = try await BenchmarkRunner(sampleRate: 2).run(clip: clip, manifest: manifest)
        print("OCR BENCHMARK\n" + report.summary)
        #expect(report.sampleCount >= 40)
        #expect(report.exactMatchRate >= 0.8, "\(report.summary)")
        #expect(report.meanCharacterAccuracy >= 0.9, "\(report.summary)")
    }
}
