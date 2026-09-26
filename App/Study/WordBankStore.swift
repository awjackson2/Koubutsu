import CoreGraphics
import Foundation
import KoubutsuCore
import Observation
import UIKit

/// The saved-word bank on disk: Documents/WordBank/wordbank.json plus JPEG line crops. On device only.
@MainActor
@Observable
final class WordBankStore {
    private(set) var bank = WordBank()
    @ObservationIgnored let directory: URL
    @ObservationIgnored private let fsrs = FSRS()

    init(directory: URL? = nil) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directory = directory ?? documents.appendingPathComponent("WordBank", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: fileURL), let loaded = try? JSONDecoder().decode(WordBank.self, from: data) {
            bank = loaded
        }
    }

    private var fileURL: URL { directory.appendingPathComponent("wordbank.json") }
    private var imagesDirectory: URL { directory.appendingPathComponent("images", isDirectory: true) }

    func isSaved(_ result: LookupResult) -> Bool {
        bank.contains(entryID: result.entry.id, headword: result.headword)
    }

    /// Saves a looked-up word with its context. `image` is the line cropped from the frozen frame.
    func save(_ result: LookupResult, sentence: String?, translation: String?, source: String?, mediaTime: Double?,
              image: CGImage?, now: Date = Date()) {
        guard !isSaved(result) else { return }
        var word = SavedWord(entryID: result.entry.id, headword: result.headword, reading: result.reading,
                             meanings: result.entry.senses.prefix(3).map { $0.glosses.prefix(4).joined(separator: "; ") },
                             sentence: sentence, sentenceTranslation: translation, source: source,
                             mediaTime: mediaTime, created: now)
        if let image, let jpeg = UIImage(cgImage: image).jpegData(compressionQuality: 0.8) {
            let name = "\(word.id.uuidString).jpg"
            if (try? jpeg.write(to: imagesDirectory.appendingPathComponent(name), options: .atomic)) != nil {
                word.imageFile = name
            }
        }
        bank.add(word)
        persist()
    }

    func delete(_ word: SavedWord) {
        if let file = word.imageFile { try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(file)) }
        bank.remove(id: word.id)
        persist()
    }

    func setKnown(_ known: Bool, for word: SavedWord) {
        bank.setKnown(known, id: word.id)
        persist()
    }

    func record(_ rating: ReviewRating, for word: SavedWord, now: Date = Date()) {
        bank.record(rating, id: word.id, now: now, scheduler: fsrs)
        persist()
    }

    func preview(_ word: SavedWord, now: Date = Date()) -> [ReviewRating: TimeInterval] {
        fsrs.preview(word.card, now: now)
    }

    func image(for word: SavedWord) -> UIImage? {
        word.imageFile.flatMap { UIImage(contentsOfFile: imagesDirectory.appendingPathComponent($0).path) }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(bank) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// "5m", "3h", "4d", "2mo", "1.5y".
enum IntervalFormat {
    static func short(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60, hours = minutes / 60, days = hours / 24
        if minutes < 60 { return "\(max(1, Int(minutes.rounded())))m" }
        if hours < 24 { return "\(Int(hours.rounded()))h" }
        if days < 30 { return "\(Int(days.rounded()))d" }
        if days < 365 { return "\(Int((days / 30).rounded()))mo" }
        return String(format: "%.1fy", days / 365)
    }
}
