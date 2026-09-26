/// Expected text for one time range of a benchmark clip.
public struct BenchmarkCheckpoint: Sendable, Hashable {
    public var id: String
    public var start: Double
    public var end: Double
    public var expected: [String]

    public init(id: String, start: Double, end: Double, expected: [String]) {
        self.id = id
        self.start = start
        self.end = end
        self.expected = expected
    }
}

/// One OCR sample of a benchmark run: clip time and recognized strings.
public struct BenchmarkSample: Sendable, Hashable {
    public var time: Double
    public var recognized: [String]
    public var ocrDuration: Double

    public init(time: Double, recognized: [String], ocrDuration: Double) {
        self.time = time
        self.recognized = recognized
        self.ocrDuration = ocrDuration
    }
}

public struct BenchmarkExpectationResult: Sendable, Hashable {
    public var checkpointID: String
    public var expected: String
    /// Best recognized string over the checkpoint's samples.
    public var bestMatch: String?
    public var characterAccuracy: Double
    public var exactMatch: Bool
    /// Clip time from checkpoint start until the text was first recognized exactly (nil = never).
    public var detectionLatency: Double?
}

public struct BenchmarkReport: Sendable, Hashable {
    public var results: [BenchmarkExpectationResult]
    public var sampleCount: Int
    public var meanOCRDuration: Double

    public var exactMatchRate: Double {
        results.isEmpty ? 0 : Double(results.filter(\.exactMatch).count) / Double(results.count)
    }

    public var meanCharacterAccuracy: Double {
        results.isEmpty ? 0 : results.map(\.characterAccuracy).reduce(0, +) / Double(results.count)
    }

    public var missed: [BenchmarkExpectationResult] { results.filter { $0.bestMatch == nil || $0.characterAccuracy < 0.5 } }

    public var summary: String {
        var lines = [
            "samples: \(sampleCount), mean OCR: \(Int(meanOCRDuration * 1000)) ms",
            "exact match: \(Int((exactMatchRate * 100).rounded()))%, char accuracy: \(Int((meanCharacterAccuracy * 100).rounded()))%",
        ]
        for r in results {
            let latency = r.detectionLatency.map { "\(Int($0 * 1000)) ms" } ?? "—"
            lines.append("  [\(r.checkpointID)] \(r.exactMatch ? "✓" : "✗") \(r.expected) → \(r.bestMatch ?? "∅") "
                         + "(acc \(Int((r.characterAccuracy * 100).rounded()))%, detect \(latency))")
        }
        return lines.joined(separator: "\n")
    }
}

/// Scores OCR samples against checkpoint expectations. Matching is on `TextNormalizer` keys and uses
/// containment so a recognized line holding the expected text plus a decoration still counts.
public enum OCRBenchmark {
    public static func evaluate(checkpoints: [BenchmarkCheckpoint], samples: [BenchmarkSample]) -> BenchmarkReport {
        var results: [BenchmarkExpectationResult] = []
        for checkpoint in checkpoints {
            let window = samples.filter { $0.time >= checkpoint.start && $0.time < checkpoint.end }
            for expected in checkpoint.expected {
                let key = TextNormalizer.key(expected)
                var best: (String, Double)?
                var firstExact: Double?
                for sample in window {
                    for text in sample.recognized {
                        let recognizedKey = TextNormalizer.key(text)
                        let accuracy = recognizedKey.contains(key)
                            ? 1.0 : TextNormalizer.characterAccuracy(expected: expected, recognized: text)
                        if best == nil || accuracy > best!.1 { best = (text, accuracy) }
                        if accuracy == 1, firstExact == nil { firstExact = sample.time - checkpoint.start }
                    }
                }
                results.append(BenchmarkExpectationResult(
                    checkpointID: checkpoint.id, expected: expected, bestMatch: best?.0,
                    characterAccuracy: best?.1 ?? 0, exactMatch: firstExact != nil, detectionLatency: firstExact))
            }
        }
        let meanOCR = samples.isEmpty ? 0 : samples.map(\.ocrDuration).reduce(0, +) / Double(samples.count)
        return BenchmarkReport(results: results, sampleCount: samples.count, meanOCRDuration: meanOCR)
    }
}
