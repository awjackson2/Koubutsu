import KoubutsuCore
import Testing
@testable import Koubutsu

/// The simulator has no UVC hardware; these tests pin down behavior without it.
@Suite(.timeLimit(.minutes(2)))
struct CaptureTests {
    @Test func noExternalDevicesInSimulator() {
        #expect(UVCVideoSource.discoverDevices().isEmpty)
    }

    @Test func missingSpecificDeviceFails() async {
        let source = UVCVideoSource(deviceID: "not-a-device")
        await #expect(throws: VideoSourceError.noDeviceAvailable) { try await source.start() }
    }

    @MainActor
    @Test func audioServiceReportsMissingUSBInput() {
        let audio = CaptureAudioService()
        audio.start()
        if case .running = audio.state {
            Issue.record("no USB audio input should exist in the simulator")
        }
        audio.stop()
    }
}
