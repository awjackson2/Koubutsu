import Foundation
import KoubutsuCore
import Synchronization
import Testing
@testable import Koubutsu

final class TableTranslator: KoubutsuCore.TranslationService {
    let providerName = "Table"
    let sendsDataOffDevice = false
    let usesContext = false
    let availabilityValue: TranslationAvailability
    let table: [String: String]
    let calls = Atomic<Int>(0)

    init(_ table: [String: String], availability: TranslationAvailability = .installed) {
        self.table = table
        availabilityValue = availability
    }

    func availability(source: String, target: String) async -> TranslationAvailability { availabilityValue }

    func translate(_ request: TranslationRequest) async throws(KoubutsuCore.TranslationError) -> String {
        calls.add(1, ordering: .relaxed)
        guard let value = table[request.text] else { throw .failed("missing") }
        return value
    }
}

private let dialogueBox = NormalizedRect(x: 0.1, y: 0.75, width: 0.5, height: 0.06)

private func ocr(_ text: String, at t: Double, box: NormalizedRect = dialogueBox) -> OCRResult {
    let frame = FrameTiming(sequence: UInt64(t * 60), presentationTime: MediaTime(seconds: t),
                            hostTime: HostTime(seconds: t), sourceSessionID: 1)
    let obs = RecognizedTextObservation(text: text, confidence: 0.9,
                                        boundingBox: box, frame: frame)
    return OCRResult(frame: frame, frameSize: .init(width: 1920, height: 1080), observations: [obs],
                     started: frame.hostTime, finished: frame.hostTime.adding(0.05), configuration: .japanese)
}

@Suite(.timeLimit(.minutes(2)))
@MainActor
struct TranslationControllerTests {
    @Test func stableTextIsTranslatedOnceAndCached() async {
        let translator = TableTranslator(["鍵が必要です": "You need a key."])
        let metrics = PipelineMetrics(clock: AppleHostClock())
        let controller = TranslationController(service: translator, metrics: metrics, clock: AppleHostClock())
        await controller.refreshAvailability()
        for i in 0..<10 { controller.process(ocr("鍵が必要です", at: Double(i) * 0.2)) }
        let done = await waitUntil(timeout: 5) { controller.displayed.first?.translation != nil }
        #expect(done)
        #expect(controller.displayed.first?.translation == "You need a key.")
        #expect(translator.calls.load(ordering: .relaxed) == 1)
        #expect(controller.history.entries.map(\.source) == ["鍵が必要です"])
        #expect(controller.history.entries.first?.translation == "You need a key.")
        #expect(metrics.snapshot().duplicateTextDetections == 9)
        #expect(metrics.snapshot().captureToDisplayLatency.count == 1)
    }

    @Test func firstReadingShowsEnglishAndChangesUpdateIt() async {
        let translator = TableTranslator(["ここから": "From here", "ここから先は危険だ": "It's dangerous ahead"])
        let controller = TranslationController(service: translator, metrics: PipelineMetrics(clock: AppleHostClock()),
                                               clock: AppleHostClock())
        await controller.refreshAvailability()
        controller.process(ocr("ここから", at: 0))
        #expect(controller.displayed.map(\.stable.text) == ["ここから"])
        let first = await waitUntil(timeout: 5) { controller.displayed.first?.translation == "From here" }
        #expect(first)
        // Typewriter reveal continues: same block, new text; the old English stays up until the new one lands.
        controller.process(ocr("ここから先は危険だ", at: 0.1))
        #expect(controller.displayed.count == 1)
        #expect(controller.displayed.first?.visibleTranslation == "From here")
        let updated = await waitUntil(timeout: 5) {
            controller.displayed.first?.translation == "It's dangerous ahead"
        }
        #expect(updated)
        #expect(controller.history.entries.map(\.source) == ["ここから先は危険だ"])
    }

    @Test func shownBoxFollowsTheTextWithoutRetranslating() async {
        let translator = TableTranslator(["鍵が必要です": "You need a key."])
        let controller = TranslationController(service: translator, metrics: PipelineMetrics(clock: AppleHostClock()),
                                               clock: AppleHostClock())
        await controller.refreshAvailability()
        controller.process(ocr("鍵が必要です", at: 0))
        let moved = NormalizedRect(x: 0.1, y: 0.76, width: 0.52, height: 0.06)
        controller.process(ocr("鍵が必要です", at: 0.1, box: moved))
        #expect(controller.displayed.first?.stable.boundingBox == moved)
        _ = await waitUntil(timeout: 5) { controller.displayed.first?.translation != nil }
        #expect(translator.calls.load(ordering: .relaxed) == 1)
    }

    @Test func mediaTimeGoingBackwardsClearsTheScreen() async {
        let translator = TableTranslator(["鍵が必要です": "You need a key."])
        let controller = TranslationController(service: translator, metrics: PipelineMetrics(clock: AppleHostClock()),
                                               clock: AppleHostClock())
        await controller.refreshAvailability()
        for i in 0..<3 { controller.process(ocr("鍵が必要です", at: 30 + Double(i) * 0.2)) }
        #expect(!controller.displayed.isEmpty)
        // Loop or seek backwards: what was on screen is gone.
        controller.process(ocr("扉が開いた", at: 2))
        #expect(controller.displayed.map(\.stable.text) == ["扉が開いた"])
    }

    @Test func notInstalledShowsDownloadState() async {
        let controller = TranslationController(service: TableTranslator([:], availability: .needsDownload),
                                               metrics: PipelineMetrics(clock: AppleHostClock()), clock: AppleHostClock())
        await controller.refreshAvailability()
        #expect(controller.availability == .needsDownload)
        #expect(controller.statusMessage != nil)
        controller.process(ocr("鍵が必要です", at: 0))
        controller.process(ocr("鍵が必要です", at: 0.2))
        #expect(controller.displayed.first?.status == .unavailable)
    }

    @Test func appleServiceReportsAvailabilityWithoutCrashing() async {
        // The simulator may not have translation models; the call must still complete.
        let availability = await AppleTranslationService().availability(source: "ja", target: "en")
        switch availability {
        case .installed, .needsDownload, .unsupported, .unknown: break
        }
    }
}
