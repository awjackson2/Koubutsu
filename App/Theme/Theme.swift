import SwiftUI
import UIKit

/// Koubutsu's visual identity: Heisei-era VCR on-screen display meets surveillance HUD. Paper white, ink black,
/// signal red; VCR OSD Mono for Latin UI text (Japanese falls back to the system font, or DotGothic16 for
/// decorative Japanese); hard edges, corner ticks, grain and scanlines.
enum K {
    static let paper = Color(red: 236 / 255, green: 234 / 255, blue: 228 / 255)
    static let ink = Color(red: 13 / 255, green: 13 / 255, blue: 15 / 255)
    static let red = Color(red: 227 / 255, green: 38 / 255, blue: 31 / 255)
    static let grey = Color(red: 138 / 255, green: 138 / 255, blue: 138 / 255)
    /// Raised ink surface (bars, panels on the dark side).
    static let inkRaised = Color(red: 24 / 255, green: 24 / 255, blue: 27 / 255)
    static let paperShade = Color(red: 222 / 255, green: 220 / 255, blue: 214 / 255)

    static let uiRed = UIColor(red: 227 / 255, green: 38 / 255, blue: 31 / 255, alpha: 1)
    static let uiInk = UIColor(red: 13 / 255, green: 13 / 255, blue: 15 / 255, alpha: 1)
    static let uiPaper = UIColor(red: 236 / 255, green: 234 / 255, blue: 228 / 255, alpha: 1)

    static let osdFontName = "VCROSDMono"
    static let dotFontName = "DotGothic16-Regular"

    /// VCR OSD Mono (monospaced, uppercase-friendly). Japanese glyphs fall back to the system font.
    static func osd(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(osdFontName, size: size, relativeTo: style)
    }

    /// DotGothic16: pixel Japanese for labels and decoration (not for dictionary content, where detail matters).
    static func dot(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(dotFontName, size: size, relativeTo: style)
    }

    /// Exact sizes for text fitted into boxes (no Dynamic Type scaling).
    static func osdFixed(_ size: CGFloat) -> Font { .custom(osdFontName, fixedSize: size) }
    static func dotFixed(_ size: CGFloat) -> Font { .custom(dotFontName, fixedSize: size) }

    static func uiOSD(_ size: CGFloat) -> UIFont {
        UIFont(name: osdFontName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Stepped animation used across the UI: quick, slightly mechanical.
    static let snap = Animation.timingCurve(0.2, 0.9, 0.1, 1, duration: 0.18)
    static let reveal = Animation.easeOut(duration: 0.24)

    /// UIKit-backed pieces SwiftUI cannot style directly (navigation bars, lists, alerts, text fields).
    @MainActor
    static func applyUIKitAppearance() {
        let bar = UINavigationBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = uiPaper
        bar.shadowColor = uiInk
        bar.titleTextAttributes = [.font: uiOSD(18), .foregroundColor: uiInk]
        bar.largeTitleTextAttributes = [.font: uiOSD(30), .foregroundColor: uiInk]
        let button = UIBarButtonItemAppearance()
        button.normal.titleTextAttributes = [.font: uiOSD(16), .foregroundColor: uiRed]
        bar.buttonAppearance = button
        bar.doneButtonAppearance = button
        UINavigationBar.appearance().standardAppearance = bar
        UINavigationBar.appearance().scrollEdgeAppearance = bar
        UINavigationBar.appearance().compactAppearance = bar
        UINavigationBar.appearance().tintColor = uiRed
        UITextField.appearance().tintColor = uiRed
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = uiRed
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
}

/// Which side of the identity a surface is on.
enum KSurface {
    /// Ink background, paper text (bars and panels around the video).
    case ink
    /// Paper background, ink text (sheets, cards, settings).
    case paper

    var background: Color { self == .ink ? K.ink : K.paper }
    var foreground: Color { self == .ink ? K.paper : K.ink }
    var secondary: Color { self == .ink ? K.paper.opacity(0.55) : K.ink.opacity(0.55) }
    var hairline: Color { self == .ink ? K.paper.opacity(0.18) : K.ink.opacity(0.18) }
}

private struct SurfaceKey: EnvironmentKey {
    static let defaultValue = KSurface.ink
}

extension EnvironmentValues {
    var kSurface: KSurface {
        get { self[SurfaceKey.self] }
        set { self[SurfaceKey.self] = newValue }
    }
}

extension View {
    /// Sets the surface for descendants (colors of components) and paints its background.
    func kSurface(_ surface: KSurface, paint: Bool = true) -> some View {
        environment(\.kSurface, surface)
            .foregroundStyle(surface.foreground)
            .background { if paint { surface.background.ignoresSafeArea() } }
    }
}
