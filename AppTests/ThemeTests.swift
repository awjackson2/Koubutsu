import SwiftUI
import Testing
import UIKit
@testable import Koubutsu

@MainActor
struct ThemeTests {
    @Test func bundledFontsAreRegistered() {
        #expect(UIFont(name: K.osdFontName, size: 16) != nil, "VCR OSD Mono missing: \(UIFont.familyNames.sorted())")
        #expect(UIFont(name: K.dotFontName, size: 16) != nil, "DotGothic16 missing")
    }

    @Test func pixelArtIsInTheAssetCatalog() {
        for name in ["px.play", "px.study", "px.words", "px.settings", "px.furigana", "LogoMark", "Wordmark", "Grain"] {
            #expect(UIImage(named: name) != nil, "missing asset \(name)")
        }
        #expect(UIImage(named: "px.play")?.size == CGSize(width: 16, height: 16))
    }
}
