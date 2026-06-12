import Foundation

/// JSON-on-disk cache for Codable values with TTL, used for
/// stale-while-revalidate and offline fallbacks on list screens.
final class DiskCache {
    static let shared = DiskCache()

    private struct Entry<T: Codable>: Codable {
        let savedAt: Date
        let value: T
    }

    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "jp.happyhome.diskcache", qos: .utility)

    init(folderName: String = "HappyHomeCache") {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = caches.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        // Keys may contain characters that are invalid in file names.
        let safe = key.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? String($0) : "_" }.joined()
        return directory.appendingPathComponent(safe + ".json")
    }

    func save<T: Codable>(_ value: T, key: String) {
        let entry = Entry(savedAt: Date(), value: value)
        guard let data = try? encoder.encode(entry) else { return }
        let url = fileURL(for: key)
        queue.async {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Loads a cached value. `maxAge` nil means "any age is acceptable"
    /// (used as an offline fallback).
    func load<T: Codable>(_ type: T.Type, key: String, maxAge: TimeInterval? = nil) -> T? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url),
              let entry = try? decoder.decode(Entry<T>.self, from: data) else {
            return nil
        }
        if let maxAge, Date().timeIntervalSince(entry.savedAt) > maxAge {
            return nil
        }
        return entry.value
    }

    func remove(key: String) {
        let url = fileURL(for: key)
        queue.async {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
