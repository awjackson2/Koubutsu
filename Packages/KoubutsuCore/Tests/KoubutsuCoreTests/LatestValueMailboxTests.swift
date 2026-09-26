import Testing
@testable import KoubutsuCore

struct LatestValueMailboxTests {
    @Test func newerValueDisplacesOlder() {
        let box = LatestValueMailbox<Int>()
        #expect(box.offer(1) == nil)
        #expect(box.offer(2) == 1)
        #expect(box.offer(3) == 2)
        #expect(box.tryTake() == 3)
        #expect(box.tryTake() == nil)
        let s = box.statistics
        #expect(s.offered == 3 && s.dropped == 2 && s.delivered == 1 && s.pending == 0)
    }

    @Test func awaitingConsumerReceivesNextOffer() async {
        let box = LatestValueMailbox<Int>()
        async let received = box.next()
        // Give the consumer a chance to suspend; correctness does not depend on it.
        try? await Task.sleep(for: .milliseconds(20))
        box.offer(42)
        #expect(await received == 42)
        #expect(box.statistics.dropped == 0)
    }

    @Test func consumerAlwaysGetsNewestUnderBurst() async {
        let box = LatestValueMailbox<Int>()
        for i in 0..<1000 { box.offer(i) }
        #expect(await box.next() == 999)
        #expect(box.statistics.dropped == 999)
    }

    @Test func closeWakesConsumerWithNil() async {
        let box = LatestValueMailbox<Int>()
        async let received = box.next()
        try? await Task.sleep(for: .milliseconds(20))
        box.close()
        #expect(await received == nil)
        box.offer(1)
        #expect(box.tryTake() == nil)
    }

    @Test func cancellationReturnsNil() async {
        let box = LatestValueMailbox<Int>()
        let task = Task { await box.next() }
        try? await Task.sleep(for: .milliseconds(20))
        task.cancel()
        #expect(await task.value == nil)
        // Mailbox still usable after a cancelled consumer.
        box.offer(7)
        #expect(await box.next() == 7)
    }

    @Test func slowConsumerNeverQueues() async {
        let box = LatestValueMailbox<Int>()
        let consumer = Task { () -> [Int] in
            var got: [Int] = []
            while let v = await box.next() {
                got.append(v)
                try? await Task.sleep(for: .milliseconds(5))
            }
            return got
        }
        for i in 0..<200 {
            box.offer(i)
            try? await Task.sleep(for: .microseconds(200))
        }
        try? await Task.sleep(for: .milliseconds(30))
        box.close()
        let got = await consumer.value
        #expect(got == got.sorted())
        #expect(got.count < 200)
        let s = box.statistics
        #expect(s.delivered + s.dropped == s.offered)
    }
}
