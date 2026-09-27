import Testing
@testable import KoubutsuCore

struct TranslationBackoffTests {
    @Test func staysClosedBelowTheThreshold() {
        var backoff = TranslationBackoff(threshold: 3, initialDelay: 15, maximumDelay: 120)
        #expect(backoff.recordFailure(at: 0) == nil)
        #expect(backoff.recordFailure(at: 1) == nil)
        #expect(backoff.allows(at: 2))
    }

    @Test func opensAtTheThresholdAndDoublesToTheCap() {
        var backoff = TranslationBackoff(threshold: 3, initialDelay: 15, maximumDelay: 120)
        backoff.recordFailure(at: 0)
        backoff.recordFailure(at: 0)
        #expect(backoff.recordFailure(at: 10) == 15)
        #expect(!backoff.allows(at: 20))
        #expect(backoff.remaining(at: 20) == 5)
        #expect(backoff.allows(at: 25))
        #expect(backoff.recordFailure(at: 25) == 30)
        #expect(backoff.recordFailure(at: 60) == 60)
        #expect(backoff.recordFailure(at: 200) == 120)
        #expect(backoff.recordFailure(at: 400) == 120)
    }

    @Test func successAndResetClose() {
        var backoff = TranslationBackoff(threshold: 1, initialDelay: 10, maximumDelay: 10)
        backoff.recordFailure(at: 0)
        #expect(!backoff.allows(at: 5))
        backoff.recordSuccess()
        #expect(backoff.allows(at: 5))
        #expect(backoff.consecutiveFailures == 0)
        backoff.recordFailure(at: 0)
        backoff.reset()
        #expect(backoff.allows(at: 1))
        #expect(backoff.remaining(at: 1) == 0)
    }
}
