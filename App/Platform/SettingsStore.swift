import Foundation
import KoubutsuCore

/// Persists `AppSettings` as JSON in `UserDefaults`. Unknown or missing keys fall back to defaults
/// (see `AppSettings.init(from:)`), so settings survive app updates that add new options.
struct SettingsStore {
    static let key = "settings.v1"
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else { return AppSettings() }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
