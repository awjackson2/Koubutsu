import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

/// Real Vision OCR against real decoded frames of the committed synthetic clip.
@Suite(.serialized, .timeLimit(.minutes(2)))
struct OCRFixtureTests {
    let manifest: ClipManifest
    let clipURL: URL
    let service = VisionOCRService()

    init() throws {
        manifest = try ClipManifest.load(named: MediaLibrary.defaultClipName)
        clipURL = try #require(MediaLibrary.defaultItem?.url)
    }

    private func recognize(_ checkpointID: String, roi: NormalizedRect? = nil) async throws
        -> (ClipManifest.Checkpoint, OCRResult) {
        let checkpoint = try #require(manifest.checkpoint(checkpointID))
        let frame = try await ClipFrameReader.frame(at: checkpoint.sampleTime, in: clipURL)
        var configuration = OCRConfiguration.japanese
        configuration.regionOfInterest = roi
        let result = try await service.recognize(frame, configuration: configuration)
        return (checkpoint, result)
    }

    /// Finds the observation whose text contains the expected core text.
    private func match(_ expected: ClipManifest.Expected, in result: OCRResult, core: String? = nil)
        -> RecognizedTextObservation? {
        let needle = squashed(core ?? expected.text)
        return result.observations.first { squashed($0.text).contains(needle) }
    }

    @Test func dialogueLinesRecognizedWithAccurateBoxes() async throws {
        let (checkpoint1, result1) = try await recognize("dialogue_line1")
        let line1 = try #require(checkpoint1.expected.first)
        let obs1 = try #require(match(line1, in: result1, core: "この先には強い敵がいる"),
                                "got: \(result1.observations.map(\.text))")
        #expect(obs1.boundingBox.iou(line1.box) >= 0.5, "box \(obs1.boundingBox) vs \(line1.box)")
        #expect(obs1.confidence > 0.3)

        let (checkpoint2, result2) = try await recognize("dialogue_line2")
        let line2 = try #require(checkpoint2.expected.first)
        let obs2 = try #require(match(line2, in: result2), "got: \(result2.observations.map(\.text))")
        #expect(obs2.boundingBox.iou(line2.box) >= 0.5, "box \(obs2.boundingBox) vs \(line2.box)")
    }

    @Test func regionOfInterestResultsMapToFullFrame() async throws {
        let (checkpoint, result) = try await recognize("dialogue_line2", roi: AppSettings.dialogueRegion)
        let line2 = try #require(checkpoint.expected.first)
        let obs = try #require(match(line2, in: result), "got: \(result.observations.map(\.text))")
        #expect(obs.boundingBox.iou(line2.box) >= 0.5, "box \(obs.boundingBox) vs \(line2.box)")
        #expect(result.observations.allSatisfy { AppSettings.dialogueRegion.intersection($0.boundingBox) != nil })
    }

    @Test func titleAndMenuRecognized() async throws {
        let (_, title) = try await recognize("title")
        #expect(title.observations.contains { squashed($0.text).contains("冒険を始めますか") },
                "got: \(title.observations.map(\.text))")
        let (menuCheckpoint, menu) = try await recognize("menu")
        let items = menuCheckpoint.expected.map(\.text).filter { ["アイテム", "ステータス", "セーブ"].contains($0) }
        for item in items {
            #expect(menu.observations.contains { squashed($0.text).contains(item) },
                    "\(item) missing from \(menu.observations.map(\.text))")
        }
    }

    @Test func renderedSystemFontTextRecognized() async throws {
        let frame = try ClipFrameReader.renderedText("鍵が必要です")
        let result = try await service.recognize(frame, configuration: .japanese)
        #expect(result.observations.contains { squashed($0.text).contains("鍵が必要です") },
                "got: \(result.observations.map(\.text))")
    }
}
