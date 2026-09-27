import KoubutsuCore
import SwiftUI

/// Settings as a printed spec sheet: numbered sections, pixel switches, boxed pickers.
struct SettingsView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var narrow = false
    /// The wordmark grows with Dynamic Type instead of staying at a fixed height.
    @ScaledMetric(relativeTo: .body) private var wordmarkHeight: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Settings", subtitle: "KOUBUTSU · PROTOCOL v0.9") {
                Button { dismiss() } label: { Text("Done").kButtonTarget() }.buttonStyle(.k(.secondary))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Display", 1) {
                        row("Show translations as") {
                            KChoicePicker(selection: $settings.displayMode, options: [
                                (.overlay, "Overlay"), (.panel, "Panel"), (.panelAndOverlay, "Both")])
                        }
                        row("Over Japanese text") {
                            KChoicePicker(selection: $settings.overlayStyle, options: [
                                (.english, "English"), (.furigana, "Furigana")])
                        }
                        toggles {
                            toggle("Show translation", $settings.showTranslation)
                            toggle("Japanese in translation panel", $settings.showOriginalText)
                            toggle("Japanese text list", $settings.showRecognizedText)
                            toggle("OCR boxes", $settings.showOCRBoxes)
                            toggle("Debug statistics", $settings.showDebugStatistics)
                        }
                        row("English text size · \(percent(settings.overlayTextScale))") {
                            KSlider(value: $settings.overlayTextScale, range: AppSettings.overlayTextScaleRange, step: 0.1)
                                .kAdjustable("English text size", value: percent(settings.overlayTextScale),
                                             binding: $settings.overlayTextScale,
                                             range: AppSettings.overlayTextScaleRange, step: 0.1)
                        }
                        toggle("Keep screen awake while running", $settings.keepScreenAwake)
                    }
                    section("Recognition", 2) {
                        row("OCR rate") {
                            KChoicePicker(selection: $settings.ocrRate,
                                          options: AppSettings.OCRRate.allCases.map { (value: $0, title: $0.label) })
                        }
                        row("OCR quality") {
                            KChoicePicker(selection: $settings.ocrQuality, options: [(.fast, "Fast"), (.accurate, "Accurate")])
                        }
                        row("Region") {
                            KChoicePicker(selection: $settings.regionOfInterestMode, options: [
                                (.fullFrame, "Full screen"), (.dialogue, "Dialogue 40%"), (.custom, "Custom")])
                        }
                    }
                    section("Translation", 3) {
                        row("Mode") {
                            KChoicePicker(selection: $settings.translationMode, options: [
                                (.lowLatency, "Low latency"), (.higherQuality, "Higher quality")])
                        }
                        note("Japanese → English. Translation runs on device. Text and video never leave the device.")
                    }
                    section("Capture device", 4) {
                        toggles {
                            toggle("Switch to capture device when connected", $settings.autoSwitchToCapture)
                            toggle("Play capture audio", $settings.playCaptureAudio)
                        }
                        row("Volume · \(percent(settings.captureAudioVolume))") {
                            KSlider(value: $settings.captureAudioVolume, range: 0...1, step: 0.05)
                                .kAdjustable("Capture audio volume", value: percent(settings.captureAudioVolume),
                                             binding: $settings.captureAudioVolume, range: 0...1, step: 0.05)
                        }
                    }
                    section("Test video", 5) {
                        toggle("Loop test video", $settings.loopTestVideo)
                    }
                    section("Shortcuts", 6) {
                        note("Hold on the video to see the original Japanese. In full screen, tap the video to show the controls.")
                        note("S study · W word bank · R review · F full screen · T English/furigana/Japanese · H recent lines · Space play/pause · ← → 10 s · ⌘, settings")
                    }
                    section("Licences", 7) {
                        note("Dictionary data: JMdict and KANJIDIC2 by the Electronic Dictionary Research and Development Group, used under Creative Commons Attribution-ShareAlike 4.0. The bundled dictionary database is a conversion of these files and is distributed under the same licence.")
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) { licenceLinks }
                            VStack(alignment: .leading, spacing: 12) { licenceLinks }
                        }
                        .buttonStyle(.k(.secondary))
                        note("Fonts: VCR OSD Mono by Riciery Leal (free); DotGothic16 by the DotGothic16 Project Authors (SIL Open Font License 1.1). Pixel art: original, generated by Tools/pixel_art.py.")
                    }
                    Image("Wordmark")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: wordmarkHeight)
                        .padding(.top, 8)
                        .accessibilityHidden(true)
                }
                .toggleStyle(.k)
                .padding(narrow ? 16 : 24)
            }
        }
        .trackingNarrowWidth($narrow)
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
    }

    @ViewBuilder private var licenceLinks: some View {
        Link(destination: URL(string: "https://www.edrdg.org/edrdg/licence.html")!) {
            Text("EDRDG licence").kButtonTarget()
        }
        Link(destination: URL(string: "https://www.edrdg.org/jmdict/j_jmdict.html")!) {
            Text("JMdict project").kButtonTarget()
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func section<Content: View>(_ title: String, _ index: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            KSectionHeader(title: title, index: index).kHeading()
            content()
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(K.osd(14)).foregroundStyle(K.ink.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }

    /// Consecutive switches without extra spacing: each is 44 pt tall, so the row pitch stays close to the old one.
    private func toggles<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
    }

    /// A pixel switch whose label is at least 44 pt tall (the whole row is the switch's hit area).
    private func toggle(_ title: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).frame(minHeight: 44, alignment: .leading)
        }
        .accessibilityAddTraits(.isToggle)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(K.osd(13)).foregroundStyle(K.ink.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
    }
}
