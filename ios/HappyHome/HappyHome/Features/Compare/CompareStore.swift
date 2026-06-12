import Foundation
import SwiftUI

/// Holds up to 3 properties chosen for side-by-side comparison.
@MainActor
final class CompareStore: ObservableObject {
    static let maxCount = 3

    @Published private(set) var items: [Property] = []

    var isFull: Bool { items.count >= Self.maxCount }

    func contains(_ property: Property) -> Bool {
        items.contains { $0.id == property.id }
    }

    /// Returns true if the property is now selected.
    @discardableResult
    func toggle(_ property: Property) -> Bool {
        Haptics.light()
        if let index = items.firstIndex(where: { $0.id == property.id }) {
            withAnimation { _ = items.remove(at: index) }
            return false
        }
        guard !isFull else {
            Haptics.error()
            return false
        }
        withAnimation { items.append(property) }
        return true
    }

    func remove(_ property: Property) {
        withAnimation {
            items.removeAll { $0.id == property.id }
        }
    }

    func clear() {
        withAnimation { items.removeAll() }
    }
}
