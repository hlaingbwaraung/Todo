import Foundation

protocol PropertyRepositoryProtocol {
    func properties(filters: PropertyFilters, page: Int, perPage: Int) async throws -> Paginated<Property>
    func property(id: Int) async throws -> Property
    func similar(to id: Int) async throws -> [Property]
    func categories() async throws -> [Category]

    // Stale-while-revalidate helpers (any-age cache for offline fallback).
    func cachedProperties(cacheKey: String) -> [Property]?
    func cachedCategories() -> [Category]?
}

/// Wraps APIClient + DiskCache. First pages of well-known lists are cached
/// so Home/Search render instantly and survive offline launches.
final class PropertyRepository: PropertyRepositoryProtocol {
    private let client: APIClient
    private let cache: DiskCache

    static let featuredCacheKey = "properties.featured"
    static let newestCacheKey = "properties.newest"
    private static let categoriesCacheKey = "categories"

    init(client: APIClient = .shared, cache: DiskCache = .shared) {
        self.client = client
        self.cache = cache
    }

    func properties(filters: PropertyFilters, page: Int, perPage: Int = 20) async throws -> Paginated<Property> {
        let endpoint = Endpoints.properties(query: filters.queryItems(page: page, perPage: perPage))
        let result: Paginated<Property> = try await client.send(endpoint)
        // Cache the canonical home sections for offline use.
        if page == 1 {
            if filters.featuredOnly, filters.activeCount == 0, filters.query.isEmpty {
                cache.save(result.data, key: Self.featuredCacheKey)
            } else if filters == PropertyFilters() {
                cache.save(result.data, key: Self.newestCacheKey)
            }
        }
        return result
    }

    func property(id: Int) async throws -> Property {
        let envelope: APIEnvelope<Property> = try await client.send(Endpoints.property(id: id))
        cache.save(envelope.data, key: "property.\(id)")
        return envelope.data
    }

    func similar(to id: Int) async throws -> [Property] {
        let envelope: Paginated<Property> = try await client.send(Endpoints.similarProperties(id: id))
        return envelope.data
    }

    func categories() async throws -> [Category] {
        let envelope: Paginated<Category> = try await client.send(Endpoints.categories())
        cache.save(envelope.data, key: Self.categoriesCacheKey)
        return envelope.data
    }

    func cachedProperties(cacheKey: String) -> [Property]? {
        cache.load([Property].self, key: cacheKey)
    }

    func cachedCategories() -> [Category]? {
        cache.load([Category].self, key: Self.categoriesCacheKey)
    }
}
