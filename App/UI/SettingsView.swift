import KoubutsuCore
import SwiftUI

struct SettingsView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Languages") {
                    LabeledContent("Source", value: "Japanese")
                    LabeledContent("Target", value: "English")
                }
                Section("Recognition") {
                    Picker("OCR rate", selection: $settings.ocrRate) {
                        ForEach(AppSettings.OCRRate.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    Picker("OCR quality", selection: $settings.ocrQuality) {
                        Text("Fast").tag(OCRQuality.fast)
                        Text("Accurate").tag(OCRQuality.accurate)
                    }
                    Picker("Region", selection: $settings.regionOfInterestMode) {
                        Text("Full screen").tag(AppSettings.RegionOfInterestMode.fullFrame)
                        Text("Dialogue (bottom 40%)").tag(AppSettings.RegionOfInterestMode.dialogue)
                        Text("Custom").tag(AppSettings.RegionOfInterestMode.custom)
                    }
                }
                Section("Translation") {
                    Picker("Mode", selection: $settings.translationMode) {
                        Text("Low latency").tag(AppSettings.TranslationMode.lowLatency)
                        Text("Higher quality").tag(AppSettings.TranslationMode.higherQuality)
                    }
                    Text("Translation runs on device. Text and video never leave the iPad.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Display") {
                    Picker("Show translations as", selection: $settings.displayMode) {
                        Text("Panel").tag(AppSettings.DisplayMode.panel)
                        Text("Overlay").tag(AppSettings.DisplayMode.overlay)
                        Text("Panel + overlay").tag(AppSettings.DisplayMode.panelAndOverlay)
                    }
                    Toggle("Show original Japanese", isOn: $settings.showOriginalText)
                    Toggle("Show translation", isOn: $settings.showTranslation)
                    Toggle("Show OCR boxes", isOn: $settings.showOCRBoxes)
                    Toggle("Japanese text list", isOn: $settings.showRecognizedText)
                    Toggle("Debug statistics", isOn: $settings.showDebugStatistics)
                    LabeledContent("English text size") {
                        HStack {
                            Slider(value: $settings.overlayTextScale, in: AppSettings.overlayTextScaleRange, step: 0.1)
                                .frame(maxWidth: 220)
                            Text("\(Int((settings.overlayTextScale * 100).rounded()))%")
                                .monospacedDigit()
                                .frame(width: 48, alignment: .trailing)
                        }
                    }
                    Toggle("Keep screen awake while running", isOn: $settings.keepScreenAwake)
                }
                Section("Shortcuts") {
                    Text("Hold on the video to see the original Japanese. In full screen, tap the video to show the controls.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Keyboard: S study · W word bank · R review · F full screen · T English/Japanese · H recent lines · Space play/pause · ← → 10 s · ⌘, settings")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Capture device") {
                    Toggle("Switch to capture device when connected", isOn: $settings.autoSwitchToCapture)
                    Toggle("Play capture audio", isOn: $settings.playCaptureAudio)
                    Slider(value: $settings.captureAudioVolume, in: 0...1) { Text("Volume") }
                }
                Section("Test video") {
                    Toggle("Loop test video", isOn: $settings.loopTestVideo)
                }
                Section("Licences") {
                    Text("Dictionary data: JMdict and KANJIDIC2 by the Electronic Dictionary Research and Development Group, used under Creative Commons Attribution-ShareAlike 4.0. The bundled dictionary database is a conversion of these files and is distributed under the same licence.")
                        .font(.footnote)
                    Link("EDRDG licence", destination: URL(string: "https://www.edrdg.org/edrdg/licence.html")!)
                    Link("JMdict project", destination: URL(string: "https://www.edrdg.org/jmdict/j_jmdict.html")!)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
