import Foundation
import KoubutsuCore
import Synchronization
import Testing
@testable import Koubutsu

/// Video mode transport on the bundled clip (24 s, 60 FPS).
@Suite(.serialized, .timeLimit(.minutes(2)))
struct VideoModeTests {
    private func startedSource() async throws -> (TestVideoSource, FrameRecorder) {
        let clip = try #require(MediaLibrary.defaultItem)
        let source = TestVideoSource(url: clip.url, loops: false)
        let recorder = FrameRecorder()
        source.setFrameHandler { recorder.record($0) }
        try await source.start()
        _ = await waitUntil(timeout: 10) { recorder.count >= 10 }
        return (source, recorder)
    }

    @Test func statusReportsDurationAndPlaying() async throws {
        let (source, _) = try await startedSource()
        let status = await source.playbackStatus()
        await source.stop()
        #expect(abs(status.duration - 24) < 0.1)
        #expect(status.isPlaying)
        #expect(!status.loops)
    }

    @Test func pauseRedeliversTheFrozenFrameSlowly() async throws {
        let (source, recorder) = try await startedSource()
        await source.pause()
        try? await Task.sleep(for: .milliseconds(300))
        let pausedCount = recorder.count
        try? await Task.sleep(for: .milliseconds(1000))
        let after = recorder.all.suffix(from: pausedCount)
        let status = await source.playbackStatus()
        await source.stop()
        #expect(!status.isPlaying)
        // Still-frame re-delivery at ~4 Hz (not 60 FPS) with an unchanged media time, so OCR keeps
        // reading what is on screen while nothing new is decoded.
        #expect((2...6).contains(after.count))
        #expect(Set(after.map(\.0.presentationTime)).count <= 1)
    }

    @Test func seekJumpsMediaTime() async throws {
        let (source, recorder) = try await startedSource()
        await source.pause()
        await source.seek(to: 12)
        let status = await source.playbackStatus()
        #expect(abs(status.currentTime - 12) < 0.05)
        await source.play()
        let reached = await waitUntil(timeout: 5) {
            (recorder.all.last?.0.presentationTime.seconds ?? 0) >= 12
        }
        await source.stop()
        #expect(reached)
    }
}
