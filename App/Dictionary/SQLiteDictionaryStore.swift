import Foundation
import KoubutsuCore
import SQLite3

/// The bundled JMdict/KANJIDIC2 database (`Tools/build_dictionary.py`, schema 1), opened read-only.
/// The app bundle carries it DEFLATE-compressed; `open()` decompresses it once into Application Support.
final class SQLiteDictionaryStore: DictionaryStore, @unchecked Sendable {
    static let resourceName = "koubutsu_dictionary.sqlite"
    static let resourceExtension = "deflate"

    enum OpenError: Error, CustomStringConvertible {
        case missingResource
        case decompressionFailed
        case sqlite(String)

        var description: String {
            switch self {
            case .missingResource: "The dictionary is missing from the app bundle."
            case .decompressionFailed: "The dictionary could not be unpacked."
            case .sqlite(let message): "The dictionary could not be opened: \(message)"
            }
        }
    }

    private let db: OpaquePointer
    private let lock = NSLock()
    private var entryCache: [String: [DictionaryEntry]] = [:]
    private let entryCacheLimit = 4000

    private init(db: OpaquePointer) {
        self.db = db
    }

    deinit {
        sqlite3_close(db)
    }

    /// Unpacks (first run or after an app update changed the data) and opens the database. Blocking; call off
    /// the main actor.
    static func open(bundle: Bundle = .main) throws -> SQLiteDictionaryStore {
        guard let packed = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw OpenError.missingResource
        }
        let fileManager = FileManager.default
        let directory = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                            appropriateFor: nil, create: true)
            .appendingPathComponent("Dictionary", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let packedSize = (try? packed.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let unpacked = directory.appendingPathComponent("\(resourceName)-\(packedSize).sqlite")
        if !fileManager.fileExists(atPath: unpacked.path) {
            let data = try Data(contentsOf: packed)
            guard let raw = try? (data as NSData).decompressed(using: .zlib) as Data else {
                throw OpenError.decompressionFailed
            }
            // Remove databases unpacked from earlier app versions.
            for old in (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [] {
                try? fileManager.removeItem(at: old)
            }
            try raw.write(to: unpacked, options: .atomic)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var url = unpacked
            try? url.setResourceValues(values)
        }
        var handle: OpaquePointer?
        let status = sqlite3_open_v2(unpacked.path, &handle, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil)
        guard status == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "status \(status)"
            if let handle { sqlite3_close(handle) }
            throw OpenError.sqlite(message)
        }
        return SQLiteDictionaryStore(db: handle)
    }

    func entries(forKey key: String) -> [DictionaryEntry] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = entryCache[key] { return cached }
        var result: [DictionaryEntry] = []
        var seen = Set<Int>()
        query("SELECT e.id, e.common, e.rank, e.json FROM form f JOIN entry e ON e.id = f.entry "
              + "WHERE f.key = ?1 ORDER BY e.common DESC, e.rank", key) { statement in
            let id = Int(sqlite3_column_int64(statement, 0))
            guard seen.insert(id).inserted, let json = Self.data(statement, 3) else { return }
            if let entry = try? DictionaryEntry(id: id, isCommon: sqlite3_column_int(statement, 1) != 0,
                                                rank: Int(sqlite3_column_int(statement, 2)), json: json) {
                result.append(entry)
            }
        }
        if entryCache.count >= entryCacheLimit { entryCache.removeAll(keepingCapacity: true) }
        entryCache[key] = result
        return result
    }

    func kanji(_ literal: Character) -> KanjiInfo? {
        lock.lock()
        defer { lock.unlock() }
        var result: KanjiInfo?
        query("SELECT json FROM kanji WHERE literal = ?1", String(literal)) { statement in
            if let json = Self.data(statement, 0) { result = try? KanjiInfo(literal: String(literal), json: json) }
        }
        return result
    }

    /// Runs `sql` with one text parameter; calls `row` per result row. Caller holds the lock.
    private func query(_ sql: String, _ parameter: String, row: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return }
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, parameter, -1, transient)
        while sqlite3_step(statement) == SQLITE_ROW { row(statement) }
    }

    private static func data(_ statement: OpaquePointer, _ column: Int32) -> Data? {
        guard let bytes = sqlite3_column_blob(statement, column) else { return nil }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, column)))
    }
}
