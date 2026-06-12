import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    enum ViewMode: String, CaseIterable {
        case list
        case map
    }

    @Published var state: LoadState = .idle
    @Published var results: [Property] = []
    @Published var total: Int = 0
    @Published var filters: PropertyFilters
    @Published var viewMode: ViewMode = .list
    @Published var isLoadingMore = false
    @Published var searchText: String {
        didSet { scheduleSearch() }
    }

    private var page = 1
    private var totalPages = 1
    private var debounceTask: Task<Void, Never>?
    private let repository: PropertyRepositoryProtocol

    var canLoadMore: Bool { page < totalPages }

    init(
        initialFilters: PropertyFilters = PropertyFilters(),
        repository: PropertyRepositoryProtocol = PropertyRepository()
    ) {
        self.filters = initialFilters
        self.searchText = initialFilters.query
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await loadFirstPage()
    }

    /// Debounced text search (400 ms).
    private func scheduleSearch() {
        guard searchText != filters.query else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard let self, !Task.isCancelled else { return }
            self.filters.query = self.searchText
            await self.loadFirstPage()
        }
    }

    func applyFilters(_ newFilters: PropertyFilters) async {
        var merged = newFilters
        merged.query = searchText
        merged.sort = filters.sort
        filters = merged
        await loadFirstPage()
    }

    func applySort(_ sort: SortOption) async {
        guard filters.sort != sort else { return }
        filters.sort = sort
        await loadFirstPage()
    }

    func loadFirstPage() async {
        page = 1
        totalPages = 1
        state = .loading
        do {
            let response = try await repository.properties(filters: filters, page: 1, perPage: 20)
            results = response.data
            total = response.meta?.total ?? response.data.count
            totalPages = response.meta?.totalPages ?? 1
            state = .loaded
        } catch {
            // Offline fallback for the unfiltered first page.
            if filters == PropertyFilters(),
               let cached = repository.cachedProperties(cacheKey: PropertyRepository.newestCacheKey),
               !cached.isEmpty {
                results = cached
                total = cached.count
                state = .loaded
            } else {
                results = []
                state = .failed(error.localizedDescription)
            }
        }
    }

    func loadMoreIfNeeded(current property: Property) async {
        guard property.id == results.last?.id,
              canLoadMore,
              !isLoadingMore,
              state == .loaded else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = page + 1
            let response = try await repository.properties(filters: filters, page: next, perPage: 20)
            let existing = Set(results.map(\.id))
            results.append(contentsOf: response.data.filter { !existing.contains($0.id) })
            page = next
            totalPages = response.meta?.totalPages ?? page
        } catch {
            // Silently keep the current pages; the user can scroll to retry.
        }
    }
}
