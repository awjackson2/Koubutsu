import Foundation
import Testing
@testable import KoubutsuCore

struct SettingsTests {
    @Test func defaults() {
        let s = AppSettings()
        #expect(s.ocrRate == .fps5)
        #expect(s.ocrConfiguration.languages == ["ja-JP"])
        #expect(s.ocrConfiguration.regionOfInterest == nil)
    }

    @Test func roundTrip() throws {
        var s = AppSettings()
        s.ocrRate = .fps10
        s.regionOfInterestMode = .dialogue
        s.showOCRBoxes = true
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded == s)
        #expect(decoded.ocrConfiguration.regionOfInterest == AppSettings.dialogueRegion)
    }

    @Test func toleratesMissingAndUnknownValues() throws {
        let json = #"{"ocrRate": 7, "showOCRBoxes": true, "futureSetting": 1}"#
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
        #expect(decoded.ocrRate == .fps5)
        #expect(decoded.showOCRBoxes)
        #expect(decoded.autoSwitchToCapture)
    }

    @Test func clampsVolume() throws {
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"captureAudioVolume": 3}"#.utf8))
        #expect(decoded.captureAudioVolume == 1)
    }
}
