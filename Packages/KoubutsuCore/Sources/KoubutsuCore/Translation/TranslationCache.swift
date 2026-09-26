import Synchronization

/// Least-recently-used cache of translations keyed by normalized source text and language/quality.
public final class TranslationCache: Sendable {
    public struct Key: Hashable, Sendable {
        public var sourceKey: String
        public var sourceLanguage: String
        public var targetLanguage: String
        public var quality: TranslationQuality

        public init(_ request: TranslationRequest) {
            sourceKey = TextNormalizer.key(request.text)
            sourceLanguage = request.sourceLanguage
            targetLanguage = request.targetLanguage
            quality = request.quality
        }
    }

    public struct Statistics: Sendable, Equatable {
        public var hits = 0
        public var misses = 0
        public var entries = 0
        public var evictions = 0
    }

    private struct State {
        var values: [Key: (value: String, stamp: UInt64)] = [:]
        var clock: UInt64 = 0
        var stats = Statistics()
    }

    public let capacity: Int
    private let state = Mutex(State())

    public init(capacity: Int = 2000) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    /// Looks up and records a hit or miss.
    public func lookup(_ key: Key) -> String? {
        state.withLock { s in
            s.clock += 1
            if let entry = s.values[key] {
                s.values[key] = (entry.value, s.clock)
                s.stats.hits += 1
                return entry.value
            }
            s.stats.misses += 1
            return nil
        }
    }

    public func store(_ value: String, for key: Key) {
        state.withLock { s in
            s.clock += 1
            s.values[key] = (value, s.clock)
            if s.values.count > capacity, let oldest = s.values.min(by: { $0.value.stamp < $1.value.stamp })?.key {
                s.values.removeValue(forKey: oldest)
                s.stats.evictions += 1
            }
            s.stats.entries = s.values.count
        }
    }

    public func removeAll() {
        state.withLock { s in
            s.values.removeAll()
            s.stats.entries = 0
        }
    }

    public var statistics: Statistics { state.withLock { $0.stats } }
}
