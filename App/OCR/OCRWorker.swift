import KoubutsuCore
import os
import Synchronization

/// Consumes sampled frames and runs OCR, one request at a time, entirely off the main actor.
///
/// Because the tap is a latest-value mailbox, when recognition is slower than the sampling interval the next
/// request simply uses the newest frame; older frames are dropped and counted, never queued.
final class OCRWorker<Service: OCRService>: Sendable where Service.Frame == VideoFrame {
    private let service: Service
    private let tap: SampledFrameTap
    private let metrics: PipelineMetrics
    private let clock: any HostClock
    private let configuration: Mutex<OCRConfiguration>
    private let enabled = Atomic<Bool>(true)
    private let task = Mutex<Task<Void, Never>?>(nil)
    private static var logger: Logger { Logger(subsystem: "com.awjackson2.Koubutsu", category: "OCR") }

    init(service: Service, tap: SampledFrameTap, metrics: PipelineMetrics, clock: any HostClock,
         configuration: OCRConfiguration) {
        self.service = service
        self.tap = tap
        self.metrics = metrics
        self.clock = clock
        self.configuration = Mutex(configuration)
    }

    func setConfiguration(_ newValue: OCRConfiguration) { configuration.withLock { $0 = newValue } }
    func setEnabled(_ value: Bool) { enabled.store(value, ordering: .relaxed) }

    /// Starts the loop. `onResult` / `onError` are invoked on the main actor.
    func start(onResult: @escaping @MainActor @Sendable (OCRResult) -> Void,
               onError: @escaping @MainActor @Sendable (OCRError) -> Void) {
        let loop = Task.detached(priority: .userInitiated) { [self] in
            while let frame = await tap.next() {
                guard enabled.load(ordering: .relaxed) else { continue }
                let config = configuration.withLock { $0 }
                metrics.ocrStarted()
                do throws(OCRError) {
                    let result = try await service.recognize(frame, configuration: config)
                    metrics.ocrFinished(frameHostTime: frame.timing.hostTime, started: result.started,
                                        finished: result.finished)
                    Self.log(result)
                    await onResult(result)
                } catch .cancelled {
                    metrics.ocrFailed()
                    break
                } catch {
                    metrics.ocrFailed()
                    Self.logger.error("OCR failed: \(error.description, privacy: .public)")
                    await onError(error)
                }
            }
        }
        let old = task.withLock { t -> Task<Void, Never>? in
            defer { t = loop }
            return t
        }
        old?.cancel()
    }

    func stop() {
        task.withLock { t in
            t?.cancel()
            t = nil
        }
    }

    private static func log(_ result: OCRResult) {
        guard !result.observations.isEmpty else { return }
        let text = result.observations.map(\.text).joined(separator: " | ")
        logger.debug("""
            OCR #\(result.frame.sequence) \(Int(result.recognitionDuration * 1000))ms: \(text, privacy: .public)
            """)
    }
}
