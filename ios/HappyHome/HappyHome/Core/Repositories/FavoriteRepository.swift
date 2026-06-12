import Foundation

protocol FavoriteRepositoryProtocol {
    func list() async throws -> [Property]
    func add(propertyId: Int) async throws
    func remove(propertyId: Int) async throws
    func cachedList() -> [Property]?
}

final class FavoriteRepository: FavoriteRepositoryProtocol {
    private let client: APIClient
    private let cache: DiskCache
    private static let cacheKey = "favorites"

    init(client: APIClient = .shared, cache: DiskCache = .shared) {
        self.client = client
        self.cache = cache
    }

    func list() async throws -> [Property] {
        let envelope: Paginated<Property> = try await client.send(Endpoints.favorites())
        cache.save(envelope.data, key: Self.cacheKey)
        return envelope.data
    }

    func add(propertyId: Int) async throws {
        try await client.sendVoid(Endpoints.addFavorite(propertyId: propertyId))
    }

    func remove(propertyId: Int) async throws {
        try await client.sendVoid(Endpoints.removeFavorite(propertyId: propertyId))
    }

    func cachedList() -> [Property]? {
        cache.load([Property].self, key: Self.cacheKey)
    }
}
