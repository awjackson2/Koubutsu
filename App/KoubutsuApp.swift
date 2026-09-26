import Foundation
import SwiftUI

@main
struct KoubutsuApp: App {
    /// When the app only hosts unit tests, skip the live pipeline so it does not compete with the tests for
    /// the CPU (Vision OCR on the simulator runs without the Neural Engine and is slow).
    private let isHostingTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some Scene {
        WindowGroup {
            if isHostingTests {
                Color.black
            } else {
                RootView()
            }
        }
    }
}
