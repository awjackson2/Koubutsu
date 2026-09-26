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

private func ocr(_ text: String, at t: Double) -> OCRResult {
    let frame = FrameTiming(sequence: UInt64(t * 60), presentationTime: MediaTime(seconds: t),
                            hostTime: HostTime(seconds: t), sourceSessionID: 1)
    let obs = RecognizedTextObservation(text: text, confidence: 0.9,
                                        boundingBox: NormalizedRect(x: 0.1, y: 0.75, width: 0.5, height: 0.06),
                                        frame: frame)
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
        #expect(metrics.snapshot().duplicateTextDetections == 8)
        #expect(metrics.snapshot().captureToDisplayLatency.count == 1)
    }

    @Test func typewriterTranslatesFinalTextOnly() async {
        let translator = TableTranslator(["ここから先は": "From here on"])
        let controller = TranslationController(service: translator, metrics: PipelineMetrics(clock: AppleHostClock()),
                                               clock: AppleHostClock())
        await controller.refreshAvailability()
        let full = "ここから先は"
        var t = 0.0
        for n in 1...full.count {
            controller.process(ocr(String(full.prefix(n)), at: t))
            t += 0.2
        }
        controller.process(ocr(full, at: t))
        _ = await waitUntil(timeout: 5) { controller.displayed.first?.translation != nil }
        #expect(controller.displayed.map(\.stable.text) == [full])
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
        #expect(controller.displayed.isEmpty)
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
