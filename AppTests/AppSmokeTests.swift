import KoubutsuCore
import Testing
@testable import Koubutsu

struct AppSmokeTests {
    @Test func coreLinks() {
        #expect(!CoreInfo.version.isEmpty)
    }
}
