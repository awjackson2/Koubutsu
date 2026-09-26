import Foundation
import KoubutsuCore
import Synchronization
import Testing
@testable import Koubutsu

final class FrameRecorder: Sendable {
    private let frames = Mutex<[(FrameTiming, PixelSize)]>([])
    func record(_ frame: VideoFrame) { frames.withLock { $0.append((frame.timing, frame.size)) } }
    var count: Int { frames.withLock { $0.count } }
    var all: [(FrameTiming, PixelSize)] { frames.withLock { $0 } }
}

func waitUntil(timeout: Double, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return condition()
}

@Suite(.serialized)
struct TestVideoSourceTests {
    @Test func bundledClipAndManifestArePresent() throws {
        let clip = try #require(MediaLibrary.defaultItem)
        #expect(clip.name == MediaLibrary.defaultClipName)
        #expect(Bundle.main.url(forResource: MediaLibrary.defaultClipName, withExtension: "json") != nil)
    }

    @Test func infoPlistEnablesFileSharing() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIFileSharingEnabled") as? Bool == true)
    }

    @Test func deliversTimedFrames() async throws {
        let clip = try #require(MediaLibrary.defaultItem)
        let source = TestVideoSource(url: clip.url)
        let recorder = FrameRecorder()
        source.setFrameHandler { recorder.record($0) }
        try await source.start()
        let gotFrames = await waitUntil(timeout: 10) { recorder.count >= 30 }
        await source.stop()
        #expect(gotFrames)
        let frames = recorder.all
        #expect(frames.first?.1 == PixelSize(width: 1920, height: 1080))
        for (a, b) in zip(frames, frames.dropFirst()) {
            #expect(b.0.sequence == a.0.sequence + 1)
            #expect(b.0.hostTime > a.0.hostTime)
            #expect(b.0.sourceSessionID == a.0.sourceSessionID)
        }
        // Delivery stops after stop().
        let countAfterStop = recorder.count
        try? await Task.sleep(for: .milliseconds(200))
        #expect(recorder.count == countAfterStop)
    }

    @Test func reportsFormat() async throws {
        let clip = try #require(MediaLibrary.defaultItem)
        let source = TestVideoSource(url: clip.url)
        let formats = Mutex<[VideoFormat]>([])
        source.setEventHandler { event in
            if case .formatChanged(let f) = event { formats.withLock { $0.append(f) } }
        }
        try await source.start()
        await source.stop()
        let format = try #require(formats.withLock { $0.first })
        #expect(format.size == PixelSize(width: 1920, height: 1080))
        #expect(abs(format.nominalFrameRate - 60) < 1)
        #expect(format.pixelFormatString == "420v")
    }

    @Test func missingFileFails() async {
        let source = TestVideoSource(url: URL(fileURLWithPath: "/nonexistent/clip.mp4"))
        await #expect(throws: VideoSourceError.mediaMissing("clip.mp4")) {
            try await source.start()
        }
    }

    @Test func uvcPlaceholderReportsNoDevice() async {
        let source = UVCVideoSource()
        await #expect(throws: VideoSourceError.noDeviceAvailable) {
            try await source.start()
        }
    }
}
