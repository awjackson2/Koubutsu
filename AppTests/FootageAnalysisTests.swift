import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

/// Runs the full OCR pipeline over external gameplay footage when provided.
///
/// The footage is never part of the repository. CI passes its path with `TEST_RUNNER_KOUBUTSU_FOOTAGE`
/// (xcodebuild forwards `TEST_RUNNER_`-prefixed variables to the test process as `KOUBUTSU_FOOTAGE`).
/// Without it the test is skipped, so regular CI runs are unaffected.
@Suite(.serialized, .timeLimit(.minutes(50)))
struct FootageAnalysisTests {
    static var footagePath: String? { ProcessInfo.processInfo.environment["KOUBUTSU_FOOTAGE"] }

    @Test(.enabled(if: footagePath.map { FileManager.default.fileExists(atPath: $0) } ?? false))
    func analyzeFootage() async throws {
        let url = URL(fileURLWithPath: try #require(Self.footagePath))
        let rate = Double(ProcessInfo.processInfo.environment["KOUBUTSU_FOOTAGE_FPS"] ?? "") ?? 1
        let report = try await VideoAnalyzer(sampleRate: rate).analyze(url: url)
        print("FOOTAGE REPORT\n" + report.summary)
        Attachment.record(report.summary, named: "footage-summary.txt")
        Attachment.record(report.transcript.srt(.japanese), named: "footage-transcript-ja.srt")
        Attachment.record(report.transcript.csv(), named: "footage-transcript.csv")
        #expect(report.sampledFrames > 0)
        #expect(report.transcript.entries.count > 0, "no stable Japanese text found in the footage")
    }
}
