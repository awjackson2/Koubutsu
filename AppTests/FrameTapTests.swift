import CoreVideo
import KoubutsuCore
import Testing
@testable import Koubutsu

enum SyntheticFrames {
    static func pixelBuffer(width: Int = 64, height: Int = 36) -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, VideoPixelFormat.fourCC,
                            VideoPixelFormat.bufferAttributes as CFDictionary, &buffer)
        return buffer!
    }

    /// 60 FPS frames with host times starting at `start`.
    static func frames(count: Int, fps: Double = 60, start: Double = 1000) -> [VideoFrame] {
        var factory = VideoFrameFactory()
        let buffer = pixelBuffer()
        return (0..<count).map { i in
            let t = start + Double(i) / fps
            let timing = FrameTiming(sequence: UInt64(i), presentationTime: MediaTime(seconds: Double(i) / fps),
                                     hostTime: HostTime(seconds: t), sourceSessionID: 1)
            return factory.makeFrame(pixelBuffer: buffer, presentationTime: timing.presentationTime.cmTime,
                                     timing: timing)!
        }
    }
}

struct FrameTapTests {
    @Test func factoryWrapsWithoutCopying() {
        let frames = SyntheticFrames.frames(count: 2)
        #expect(frames[0].pixelBuffer === frames[1].pixelBuffer)
        #expect(frames[0].size == PixelSize(width: 64, height: 36))
    }

    @Test func samplesAtTargetRateAndKeepsOnlyNewest() async {
        let metrics = PipelineMetrics(clock: AppleHostClock())
        let tap = SampledFrameTap(rate: 5, metrics: metrics)
        for frame in SyntheticFrames.frames(count: 120) { tap.offer(frame) }
        let stats = tap.statistics
        #expect(stats.offered == 10)
        #expect(stats.dropped == 9)
        let newest = await tap.next()
        #expect(newest?.timing.sequence == 108)
        #expect(metrics.snapshot().ocrDroppedFrames == 9)
    }

    @Test func pipelineFeedsTapAfterDisplay() async {
        let renderer = await SampleBufferRenderer()
        let metrics = PipelineMetrics(clock: AppleHostClock())
        let pipeline = FramePipeline(renderer: renderer, metrics: metrics, clock: AppleHostClock())
        let tap = SampledFrameTap(rate: 60, metrics: metrics)
        pipeline.setProcessingTap(tap)
        for frame in SyntheticFrames.frames(count: 3) { pipeline.handle(frame) }
        #expect(metrics.snapshot().totalFramesDisplayed == 3)
        #expect(await tap.next()?.timing.sequence == 2)
        pipeline.setProcessingTap(nil)
        let closed = await tap.next() == nil
        #expect(closed)
    }
}
