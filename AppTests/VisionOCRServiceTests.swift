import KoubutsuCore
import Synchronization
import Testing
@testable import Koubutsu

struct VisionOCRServiceTests {
    @Test func japaneseIsSupported() async {
        let service = VisionOCRService()
        let languages = await service.supportedLanguages(quality: .accurate)
        #expect(languages.contains { $0.hasPrefix("ja") })
        #expect(await service.supports(.japanese))
    }

    @Test func blankFrameYieldsNoObservations() async throws {
        let frame = SyntheticFrames.frames(count: 1)[0]
        let result = try await VisionOCRService().recognize(frame, configuration: .japanese)
        #expect(result.observations.isEmpty)
        #expect(result.finished >= result.started)
        #expect(result.frame == frame.timing)
    }

    @Test func workerProcessesNewestFrameAndStopsWhenTapCloses() async throws {
        let metrics = PipelineMetrics(clock: AppleHostClock())
        let tap = SampledFrameTap(rate: 60, metrics: metrics)
        let worker = OCRWorker(service: VisionOCRService(), tap: tap, metrics: metrics, clock: AppleHostClock(),
                               configuration: .japanese)
        let results = ResultBox()
        worker.start(onResult: { results.append($0) }, onError: { _ in })
        for frame in SyntheticFrames.frames(count: 5) { tap.offer(frame) }
        let processed = await waitUntil(timeout: 20) { results.count >= 1 }
        #expect(processed)
        #expect(metrics.snapshot().totalOCRProcessed >= 1)
        tap.close()
        worker.stop()
    }
}

final class ResultBox: Sendable {
    private let results = Mutex<[OCRResult]>([])
    func append(_ r: OCRResult) { results.withLock { $0.append(r) } }
    var count: Int { results.withLock { $0.count } }
    var all: [OCRResult] { results.withLock { $0 } }
}
