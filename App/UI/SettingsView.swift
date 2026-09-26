import KoubutsuCore
import SwiftUI

/// Settings as a printed spec sheet: numbered sections, pixel switches, boxed pickers.
struct SettingsView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Settings", subtitle: "KOUBUTSU · PROTOCOL v0.9") {
                Button("Done") { dismiss() }.buttonStyle(.k(.secondary))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Display", 1) {
                        row("Show translations as") {
                            KSegmented(selection: $settings.displayMode, options: [
                                (.overlay, "Overlay"), (.panel, "Panel"), (.panelAndOverlay, "Both")])
                        }
                        row("Over Japanese text") {
                            KSegmented(selection: $settings.overlayStyle, options: [
                                (.english, "English"), (.furigana, "Furigana")])
                        }
                        Toggle("Show translation", isOn: $settings.showTranslation)
                        Toggle("Japanese in translation panel", isOn: $settings.showOriginalText)
                        Toggle("Japanese text list", isOn: $settings.showRecognizedText)
                        Toggle("OCR boxes", isOn: $settings.showOCRBoxes)
                        Toggle("Debug statistics", isOn: $settings.showDebugStatistics)
                        row("English text size · \(Int((settings.overlayTextScale * 100).rounded()))%") {
                            KSlider(value: $settings.overlayTextScale, range: AppSettings.overlayTextScaleRange, step: 0.1)
                        }
                        Toggle("Keep screen awake while running", isOn: $settings.keepScreenAwake)
                    }
                    section("Recognition", 2) {
                        row("OCR rate") {
                            KSegmented(selection: $settings.ocrRate,
                                       options: AppSettings.OCRRate.allCases.map { (value: $0, title: $0.label) })
                        }
                        row("OCR quality") {
                            KSegmented(selection: $settings.ocrQuality, options: [(.fast, "Fast"), (.accurate, "Accurate")])
                        }
                        row("Region") {
                            KSegmented(selection: $settings.regionOfInterestMode, options: [
                                (.fullFrame, "Full screen"), (.dialogue, "Dialogue 40%"), (.custom, "Custom")])
                        }
                    }
                    section("Translation", 3) {
                        row("Mode") {
                            KSegmented(selection: $settings.translationMode, options: [
                                (.lowLatency, "Low latency"), (.higherQuality, "Higher quality")])
                        }
                        note("Japanese → English. Translation runs on device. Text and video never leave the iPad.")
                    }
                    section("Capture device", 4) {
                        Toggle("Switch to capture device when connected", isOn: $settings.autoSwitchToCapture)
                        Toggle("Play capture audio", isOn: $settings.playCaptureAudio)
                        row("Volume · \(Int((settings.captureAudioVolume * 100).rounded()))%") {
                            KSlider(value: $settings.captureAudioVolume, range: 0...1, step: 0.05)
                        }
                    }
                    section("Test video", 5) {
                        Toggle("Loop test video", isOn: $settings.loopTestVideo)
                    }
                    section("Shortcuts", 6) {
                        note("Hold on the video to see the original Japanese. In full screen, tap the video to show the controls.")
                        note("S study · W word bank · R review · F full screen · T English/furigana/Japanese · H recent lines · Space play/pause · ← → 10 s · ⌘, settings")
                    }
                    section("Licences", 7) {
                        note("Dictionary data: JMdict and KANJIDIC2 by the Electronic Dictionary Research and Development Group, used under Creative Commons Attribution-ShareAlike 4.0. The bundled dictionary database is a conversion of these files and is distributed under the same licence.")
                        HStack(spacing: 12) {
                            Link("EDRDG licence", destination: URL(string: "https://www.edrdg.org/edrdg/licence.html")!)
                            Link("JMdict project", destination: URL(string: "https://www.edrdg.org/jmdict/j_jmdict.html")!)
                        }
                        .buttonStyle(.k(.secondary))
                        note("Fonts: VCR OSD Mono by Riciery Leal (free); DotGothic16 by the DotGothic16 Project Authors (SIL Open Font License 1.1). Pixel art: original, generated by Tools/pixel_art.py.")
                    }
                    Image("Wordmark")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 36)
                        .padding(.top, 8)
                }
                .toggleStyle(.k)
                .padding(24)
            }
        }
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
    }

    private func section<Content: View>(_ title: String, _ index: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            KSectionHeader(title: title, index: index)
            content()
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(K.osd(14)).foregroundStyle(K.ink.opacity(0.6))
            content()
        }
    }

    private func note(_ text: String) -> some View {
        Text(text).font(K.osd(13)).foregroundStyle(K.ink.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
    }
}
