import Foundation

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published var state: LoadState = .idle
    @Published var property: Property
    @Published var similar: [Property] = []

    private let repository: PropertyRepositoryProtocol

    init(property: Property, repository: PropertyRepositoryProtocol = PropertyRepository()) {
        self.property = property
        self.repository = repository
    }

    /// List responses omit `description*` and `images`; when either is present
    /// we already hold the full detail payload.
    var hasFullDetail: Bool {
        property.description != nil || property.images != nil
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        state = hasFullDetail ? .loaded : .loading
        do {
            property = try await repository.property(id: property.id)
            state = .loaded
        } catch {
            // Keep rendering the list snapshot if we have one.
            state = hasFullDetail ? .loaded : .failed(error.localizedDescription)
        }
        // Similar properties are best-effort and never block the screen.
        similar = (try? await repository.similar(to: property.id)) ?? []
    }
}
