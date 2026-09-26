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
                    Toggle("Ignore HUD text (button hints, dates)", isOn: $settings.hideHUDText)
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
                    Toggle("Debug statistics", isOn: $settings.showDebugStatistics)
                }
                Section("Capture device") {
                    Toggle("Switch to capture device when connected", isOn: $settings.autoSwitchToCapture)
                    Toggle("Play capture audio", isOn: $settings.playCaptureAudio)
                    Slider(value: $settings.captureAudioVolume, in: 0...1) { Text("Volume") }
                }
                Section("Test video") {
                    Toggle("Loop test video", isOn: $settings.loopTestVideo)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
