import Foundation

/// Outcome of translating one stable text.
public struct TranslatedText: Sendable, Hashable, Identifiable {
    public var id: String { stable.id }
    public var stable: StableText
    public var translation: String
    public var provider: String
    public var fromCache: Bool
    public var started: HostTime
    public var finished: HostTime

    /// Stable text first seen on screen → translation available.
    public var captureToTranslationLatency: Double { finished - stable.firstSeenFrame.hostTime }
    public var translationDuration: Double { finished - started }
}

/// Front door for translation: cache first, then the service, with in-flight de-duplication so the same
/// text appearing in several blocks (or re-stabilizing) is translated once. Records metrics.
public actor TranslationCoordinator {
    private let service: any TranslationService
    public nonisolated let cache: TranslationCache
    private let metrics: PipelineMetrics?
    private let clock: any HostClock
    private var inFlight: [TranslationCache.Key: Task<String, any Error>] = [:]

    public init(service: any TranslationService, cache: TranslationCache = TranslationCache(),
                metrics: PipelineMetrics?, clock: any HostClock) {
        self.service = service
        self.cache = cache
        self.metrics = metrics
        self.clock = clock
    }

    public nonisolated var providerName: String { service.providerName }

    public func translate(_ stable: StableText, sourceLanguage: String = "ja", targetLanguage: String = "en",
                          quality: TranslationQuality = .lowLatency,
                          context: TranslationContext = .none) async throws(TranslationError) -> TranslatedText {
        let request = TranslationRequest(text: stable.text, sourceLanguage: sourceLanguage,
                                         targetLanguage: targetLanguage, quality: quality, context: context)
        let key = TranslationCache.Key(request)
        let started = clock.now()
        if let cached = cache.lookup(key) {
            metrics?.translationCacheHit()
            return TranslatedText(stable: stable, translation: cached, provider: service.providerName,
                                  fromCache: true, started: started, finished: clock.now())
        }
        metrics?.translationCacheMiss()

        let task: Task<String, any Error>
        if let existing = inFlight[key] {
            task = existing
        } else {
            let service = self.service
            task = Task { try await service.translate(request) }
            inFlight[key] = task
        }
        let translation: String
        do {
            translation = try await task.value
            inFlight[key] = nil
        } catch {
            inFlight[key] = nil
            metrics?.translationFailed()
            throw (error as? TranslationError) ?? .failed(String(describing: error))
        }
        cache.store(translation, for: key)
        let finished = clock.now()
        metrics?.translationFinished(frameHostTime: stable.firstSeenFrame.hostTime, started: started,
                                     finished: finished)
        return TranslatedText(stable: stable, translation: translation, provider: service.providerName,
                              fromCache: false, started: started, finished: finished)
    }

    public func availability(source: String = "ja", target: String = "en") async -> TranslationAvailability {
        await service.availability(source: source, target: target)
    }
}
