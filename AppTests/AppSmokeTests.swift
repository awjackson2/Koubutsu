import KoubutsuCore
import Testing
@testable import Koubutsu

@Suite(.timeLimit(.minutes(2)))
struct AppSmokeTests {
    @Test func coreLinks() {
        #expect(!CoreInfo.version.isEmpty)
    }
}
