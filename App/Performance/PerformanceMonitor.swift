import AVFoundation
import Darwin
import Foundation
import Observation
import os

/// Device-level health for the debug panel: CPU, memory, thermal state, and display-side frame drops.
@MainActor
@Observable
final class PerformanceMonitor {
    struct Snapshot: Equatable {
        var cpuPercent: Double = 0
        var memoryMB: Double = 0
        var thermalState: ProcessInfo.ThermalState = .nominal
        var displayTotalFrames: Int = 0
        var displayDroppedFrames: Int = 0
        var lowPowerMode = false
    }

    private(set) var snapshot = Snapshot()

    func refresh(renderer: SampleBufferRenderer) async {
        var s = Snapshot()
        s.cpuPercent = Self.cpuUsagePercent()
        s.memoryMB = Self.memoryFootprintMB()
        s.thermalState = ProcessInfo.processInfo.thermalState
        s.lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if let display = await renderer.performanceMetrics() {
            s.displayTotalFrames = display.total
            s.displayDroppedFrames = display.dropped
        }
        snapshot = s
    }

    var thermalLabel: String {
        switch snapshot.thermalState {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }

    /// Sum of CPU usage of all threads in the process (100% = one core).
    nonisolated static func cpuUsagePercent() -> Double {
        var threads: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS, let threads else { return 0 }
        defer {
            // task_threads returns a send right per thread plus the array; both must be released or the
            // process leaks Mach ports on every sample.
            for i in 0..<Int(count) { mach_port_deallocate(mach_task_self_, threads[i]) }
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)),
                          vm_size_t(Int(count) * MemoryLayout<thread_t>.stride))
        }
        var total = 0.0
        for i in 0..<Int(count) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if result == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 {
                total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }
        return total
    }

    /// Physical memory footprint (what jetsam limits), in MB.
    nonisolated static func memoryFootprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : 0
    }
}

/// Signposts for Instruments: OCR and translation intervals show up in the "Points of Interest" track.
enum Signposts {
    static let pipeline = OSSignposter(subsystem: "com.awjackson2.Koubutsu", category: .pointsOfInterest)
}
