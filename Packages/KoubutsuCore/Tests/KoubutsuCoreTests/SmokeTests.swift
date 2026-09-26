import Testing
@testable import KoubutsuCore

struct SmokeTests {
    @Test func versionIsSet() {
        #expect(CoreInfo.version == "0.1.0")
    }
}
