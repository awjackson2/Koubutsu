import KoubutsuCore

/// Fixed-table translator for the bundled synthetic clip, enabled with the `--demo-translator` launch
/// argument. Used for simulator screenshots and UI checks, where Apple's translation models are not
/// installed. Its provider name makes the substitution visible in the UI.
struct DemoTranslationService: TranslationService {
    let providerName = "Demo table (synthetic clip)"
    let sendsDataOffDevice = false
    let usesContext = false

    static let table: [String: String] = [
        "冒険を始めますか？": "Begin the adventure?",
        "はい": "Yes",
        "いいえ": "No",
        "この先には強い敵がいる。": "There is a powerful enemy ahead.",
        "鍵が必要です": "You need a key.",
        "この先には強い敵がいる。鍵が必要です": "There is a powerful enemy ahead. You need a key.",
        "セーブしています...": "Saving...",
        "メニュー": "Menu",
        "アイテム": "Items",
        "そうび": "Equipment",
        "ステータス": "Status",
        "セーブ": "Save",
        "Aボタンで決定": "Confirm with A",
    ]

    private static let byKey = Dictionary(table.map { (TextNormalizer.key($0.key), $0.value) },
                                          uniquingKeysWith: { first, _ in first })

    func availability(source: String, target: String) async -> TranslationAvailability { .installed }

    func translate(_ request: TranslationRequest) async throws(TranslationError) -> String {
        let key = TextNormalizer.key(request.text)
        if let exact = Self.byKey[key] { return exact }
        // Closest entry for OCR variations (e.g. a missed punctuation mark).
        let best = Self.byKey.max { TextNormalizer.similarity($0.key, key) < TextNormalizer.similarity($1.key, key) }
        guard let best, TextNormalizer.similarity(best.key, key) >= 0.75 else {
            throw .failed("no demo translation for \(request.text)")
        }
        return best.value
    }
}

/// Layout stand-in for footage screenshots on the simulator (no translation models there), enabled with
/// `--placeholder-translator`. Returns placeholder English about as long as a real translation of the
/// Japanese (≈2 Latin characters per Japanese character) so replace-in-place geometry and font fitting can be
/// checked on real footage. Every result starts with "[EN]" so it can never be mistaken for a translation.
struct PlaceholderTranslationService: TranslationService {
    let providerName = "Placeholder (layout check)"
    let sendsDataOffDevice = false
    let usesContext = false

    private static let words = ["english", "text", "goes", "here", "in", "place", "of", "the", "japanese", "line"]

    func availability(source: String, target: String) async -> TranslationAvailability { .installed }

    func translate(_ request: TranslationRequest) async throws(TranslationError) -> String {
        let target = max(4, TextNormalizer.key(request.text).count * 2)
        var out = "[EN]"
        var index = 0
        while out.count < target {
            out += " " + Self.words[index % Self.words.count]
            index += 1
        }
        return out
    }
}

/// Launch arguments for automation (CI screenshots, UI checks).
struct LaunchOptions {
    var demoTranslator = false
    var placeholderTranslator = false
    var resetSettings = false
    /// Select the first media item whose name contains this text (Video mode automation).
    var selectVideo: String?
    /// Seek to this media time after the source starts.
    var startAt: Double?
    /// Pause this many seconds after starting.
    var pauseAfter: Double?
    var displayMode: AppSettings.DisplayMode?
    var showBoxes: Bool?
    var showDebug: Bool?

    static let current = LaunchOptions(arguments: CommandLine.arguments)

    init(arguments: [String]) {
        for arg in arguments {
            switch arg {
            case "--demo-translator": demoTranslator = true
            case "--placeholder-translator": placeholderTranslator = true
            case "--reset-settings": resetSettings = true
            case "--show-boxes": showBoxes = true
            case "--hide-debug": showDebug = false
            case "--show-debug": showDebug = true
            default:
                if arg.hasPrefix("--select-video=") { selectVideo = String(arg.dropFirst("--select-video=".count)) }
                if arg.hasPrefix("--start-at=") { startAt = Double(arg.dropFirst("--start-at=".count)) }
                if arg.hasPrefix("--pause-after=") { pauseAfter = Double(arg.dropFirst("--pause-after=".count)) }
                if arg.hasPrefix("--display-mode=") {
                    displayMode = AppSettings.DisplayMode(rawValue: String(arg.dropFirst("--display-mode=".count)))
                }
            }
        }
    }

    func apply(to settings: inout AppSettings) {
        if resetSettings { settings = AppSettings() }
        if let displayMode { settings.displayMode = displayMode }
        if let showBoxes { settings.showOCRBoxes = showBoxes }
        if let showDebug { settings.showDebugStatistics = showDebug }
    }
}
