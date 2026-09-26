import Testing
@testable import KoubutsuCore

struct OCRBenchmarkTests {
    @Test func scoresExactPartialAndMissed() {
        let checkpoints = [
            BenchmarkCheckpoint(id: "a", start: 0, end: 2, expected: ["鍵が必要です"]),
            BenchmarkCheckpoint(id: "b", start: 2, end: 4, expected: ["この先には強い敵がいる。"]),
            BenchmarkCheckpoint(id: "c", start: 4, end: 6, expected: ["セーブしています…"]),
        ]
        let samples = [
            BenchmarkSample(time: 0.2, recognized: ["鍵か必要です"], ocrDuration: 0.1),
            BenchmarkSample(time: 0.4, recognized: ["鍵が必要です ▼"], ocrDuration: 0.1),
            BenchmarkSample(time: 2.2, recognized: ["この先にわ強い敵がいる。"], ocrDuration: 0.2),
            BenchmarkSample(time: 4.2, recognized: [], ocrDuration: 0.2),
        ]
        let report = OCRBenchmark.evaluate(checkpoints: checkpoints, samples: samples)
        #expect(report.results.count == 3)
        #expect(report.results[0].exactMatch)
        #expect(abs((report.results[0].detectionLatency ?? -1) - 0.4) < 1e-9)
        #expect(!report.results[1].exactMatch)
        #expect(report.results[1].characterAccuracy > 0.9)
        #expect(report.results[2].bestMatch == nil)
        #expect(report.missed.map(\.checkpointID) == ["c"])
        #expect(abs(report.exactMatchRate - 1.0 / 3.0) < 1e-9)
        #expect(abs(report.meanOCRDuration - 0.15) < 1e-9)
        #expect(report.summary.contains("[a] ✓"))
    }
}
