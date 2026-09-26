import AVFoundation
import Observation

/// Tracks connected external (UVC) capture devices and reports hot-plug events.
@MainActor
@Observable
final class CaptureDeviceMonitor {
    enum Change: Sendable {
        case connected(CaptureDeviceInfo)
        case disconnected(CaptureDeviceInfo)
    }

    private(set) var devices: [CaptureDeviceInfo] = []
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored var onChange: ((Change) -> Void)?

    init() {
        refresh()
        let center = NotificationCenter.default
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                let connected = note.name == AVCaptureDevice.wasConnectedNotification
                let device = note.object as? AVCaptureDevice
                let info = device.map { CaptureDeviceInfo(id: $0.uniqueID, name: $0.localizedName,
                                                          manufacturer: $0.manufacturer) }
                let isExternal = device?.deviceType == .external
                MainActor.assumeIsolated {
                    guard let self, isExternal, let info else { return }
                    self.refresh()
                    self.onChange?(connected ? .connected(info) : .disconnected(info))
                }
            })
        }
    }

    func refresh() {
        devices = UVCVideoSource.discoverDevices()
    }
}
