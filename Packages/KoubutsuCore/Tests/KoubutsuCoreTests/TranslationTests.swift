import Foundation
import Synchronization
import Testing
@testable import KoubutsuCore

final class FakeTranslator: TranslationService {
    let providerName = "Fake"
    let sendsDataOffDevice = false
    let usesContext = false
    let table: [String: String]
    let delay: Duration
    let calls = Mutex<[TranslationRequest]>([])

    init(_ table: [String: String], delay: Duration = .zero) {
        self.table = table
        self.delay = delay
    }

    func availability(source: String, target: String) async -> TranslationAvailability { .installed }

    func translate(_ request: TranslationRequest) async throws(TranslationError) -> String {
        calls.withLock { $0.append(request) }
        if delay > .zero { try? await Task.sleep(for: delay) }
        guard let value = table[request.text] else { throw .failed("no entry for \(request.text)") }
        return value
    }

    var callCount: Int { calls.withLock { $0.count } }
}

func stable(_ text: String, at t: Double = 0) -> StableText {
    let frame = FrameTiming(sequence: 0, presentationTime: .zero, hostTime: HostTime(seconds: t), sourceSessionID: 1)
    return StableText(trackID: UUID(), text: text, key: TextNormalizer.key(text),
                      boundingBox: .full, confidence: 0.9, lines: [], firstSeenFrame: frame, stabilizedFrame: frame)
}

struct TranslationTests {
    @Test func cacheLRU() {
        let cache = TranslationCache(capacity: 2)
        let a = TranslationCache.Key(TranslationRequest(text: "あ"))
        let b = TranslationCache.Key(TranslationRequest(text: "い"))
        let c = TranslationCache.Key(TranslationRequest(text: "う"))
        #expect(cache.lookup(a) == nil)
        cache.store("a", for: a)
        cache.store("b", for: b)
        #expect(cache.lookup(a) == "a")      // a is now most recent
        cache.store("c", for: c)             // evicts b
        #expect(cache.lookup(b) == nil)
        #expect(cache.lookup(c) == "c")
        let stats = cache.statistics
        #expect(stats.hits == 2 && stats.misses == 2 && stats.evictions == 1 && stats.entries == 2)
    }

    @Test func cacheKeyNormalizesText() {
        let k1 = TranslationCache.Key(TranslationRequest(text: "鍵が必要です ▼"))
        let k2 = TranslationCache.Key(TranslationRequest(text: "鍵が 必要です"))
        #expect(k1 == k2)
        #expect(k1 != TranslationCache.Key(TranslationRequest(text: "鍵が必要です", quality: .highFidelity)))
    }

    @Test func coordinatorCachesAndMeasures() async throws {
        let translator = FakeTranslator(["鍵が必要です": "You need a key."])
        let clock = ContinuousHostClock()
        let metrics = PipelineMetrics(clock: clock)
        let coordinator = TranslationCoordinator(service: translator, metrics: metrics, clock: clock)
        let first = try await coordinator.translate(stable("鍵が必要です"))
        #expect(first.translation == "You need a key.")
        #expect(!first.fromCache)
        let second = try await coordinator.translate(stable("鍵が必要です"))
        #expect(second.fromCache)
        #expect(translator.callCount == 1)
        let snap = metrics.snapshot()
        #expect(snap.translationCacheHits == 1 && snap.translationCacheMisses == 1)
        #expect(snap.translationRequests == 1)
        #expect(snap.translationLatency.count == 1)
    }

    @Test func concurrentIdenticalRequestsTranslatedOnce() async throws {
        let translator = FakeTranslator(["扉が開いた": "The door opened."], delay: .milliseconds(50))
        let coordinator = TranslationCoordinator(service: translator, metrics: nil, clock: ContinuousHostClock())
        async let a = coordinator.translate(stable("扉が開いた"))
        async let b = coordinator.translate(stable("扉が開いた"))
        let results = try await [a, b]
        #expect(results.allSatisfy { $0.translation == "The door opened." })
        #expect(translator.callCount == 1)
    }

    @Test func failuresPropagateAndAreNotCached() async {
        let translator = FakeTranslator([:])
        let metrics = PipelineMetrics(clock: ContinuousHostClock())
        let coordinator = TranslationCoordinator(service: translator, metrics: metrics, clock: ContinuousHostClock())
        await #expect(throws: TranslationError.self) { try await coordinator.translate(stable("謎")) }
        await #expect(throws: TranslationError.self) { try await coordinator.translate(stable("謎")) }
        #expect(translator.callCount == 2)
        #expect(metrics.snapshot().translationFailures == 2)
    }

    @Test func requestCarriesContext() async throws {
        let translator = FakeTranslator(["気をつけて。": "Be careful."])
        let coordinator = TranslationCoordinator(service: translator, metrics: nil, clock: ContinuousHostClock())
        let context = TranslationContext(previousDialogue: [.init(source: "敵が近くにいる。", translation: "Enemies are near.")])
        _ = try await coordinator.translate(stable("気をつけて。"), context: context)
        #expect(translator.calls.withLock { $0.first?.context.previousDialogue.count } == 1)
    }
}
