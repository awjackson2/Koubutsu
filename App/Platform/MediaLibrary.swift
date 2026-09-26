import Foundation

/// A video file that can back a `TestVideoSource`.
struct MediaItem: Hashable, Identifiable, Sendable {
    enum Origin: String, Sendable { case bundled, imported }

    let url: URL
    let origin: Origin
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

/// Finds test videos: clips bundled with the app and files the user imported (Files app or Finder sharing).
/// Imported footage stays in the app's Documents directory and is never uploaded anywhere.
enum MediaLibrary {
    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    static let defaultClipName = "synthetic_ja_1080p60"

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func bundledVideos(in bundle: Bundle = .main) -> [MediaItem] {
        videoExtensions
            .flatMap { bundle.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
            .map { MediaItem(url: $0, origin: .bundled) }
            .sorted { $0.name < $1.name }
    }

    static func importedVideos() -> [MediaItem] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: documentsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return files
            .filter { videoExtensions.contains($0.pathExtension.lowercased()) }
            .map { MediaItem(url: $0, origin: .imported) }
            .sorted { $0.name < $1.name }
    }

    static func allVideos() -> [MediaItem] { bundledVideos() + importedVideos() }

    static var defaultItem: MediaItem? {
        bundledVideos().first { $0.name == defaultClipName } ?? allVideos().first
    }

    /// Copies a user-picked file into Documents. Handles security-scoped URLs from the document picker.
    static func importVideo(from source: URL) throws -> MediaItem {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        var destination = documentsDirectory.appendingPathComponent(source.lastPathComponent)
        var suffix = 1
        while FileManager.default.fileExists(atPath: destination.path) {
            let base = source.deletingPathExtension().lastPathComponent
            destination = documentsDirectory.appendingPathComponent("\(base)-\(suffix).\(source.pathExtension)")
            suffix += 1
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return MediaItem(url: destination, origin: .imported)
    }
}
