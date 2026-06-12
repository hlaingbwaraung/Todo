import Foundation

/// Keeps snapshots of the last 20 viewed properties, persisted to disk.
@MainActor
final class RecentlyViewedStore: ObservableObject {
    @Published private(set) var items: [Property] = []

    private static let maxCount = 20
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fileURL = documents.appendingPathComponent("recently_viewed.json")
        load()
    }

    func record(_ property: Property) {
        var updated = items.filter { $0.id != property.id }
        updated.insert(property, at: 0)
        if updated.count > Self.maxCount {
            updated = Array(updated.prefix(Self.maxCount))
        }
        items = updated
        persist()
    }

    func clear() {
        items = []
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Property].self, from: data) else { return }
        items = decoded
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
