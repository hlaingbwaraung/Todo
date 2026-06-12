import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var state: LoadState = .idle
    @Published var featured: [Property] = []
    @Published var newListings: [Property] = []
    @Published var categories: [Category] = []

    private let repository: PropertyRepositoryProtocol

    init(repository: PropertyRepositoryProtocol = PropertyRepository()) {
        self.repository = repository
    }

    var hasContent: Bool {
        !featured.isEmpty || !newListings.isEmpty
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    /// Stale-while-revalidate: render the disk cache immediately, then refresh.
    func load() async {
        if !hasContent {
            if let cachedFeatured = repository.cachedProperties(cacheKey: PropertyRepository.featuredCacheKey) {
                featured = cachedFeatured
            }
            if let cachedNew = repository.cachedProperties(cacheKey: PropertyRepository.newestCacheKey) {
                newListings = cachedNew
            }
            if let cachedCategories = repository.cachedCategories() {
                categories = cachedCategories
            }
        }
        state = hasContent ? .loaded : .loading

        var featuredFilters = PropertyFilters()
        featuredFilters.featuredOnly = true
        let newFilters = PropertyFilters()

        do {
            async let featuredPage = repository.properties(filters: featuredFilters, page: 1, perPage: 10)
            async let newestPage = repository.properties(filters: newFilters, page: 1, perPage: 10)
            async let categoryList = repository.categories()

            let (featuredResult, newestResult, categoriesResult) = try await (featuredPage, newestPage, categoryList)
            featured = featuredResult.data
            newListings = newestResult.data
            categories = categoriesResult
            state = .loaded
        } catch {
            // Keep showing cached content when the refresh fails.
            state = hasContent ? .loaded : .failed(error.localizedDescription)
        }
    }
}
