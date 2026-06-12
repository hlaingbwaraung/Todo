import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showingFilters = false

    init(initialFilters: PropertyFilters = PropertyFilters()) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(initialFilters: initialFilters))
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            switch viewModel.state {
            case .idle, .loading:
                skeletons
            case .failed(let message):
                ScrollView {
                    ErrorStateView(message: message) {
                        Task { await viewModel.loadFirstPage() }
                    }
                    .padding(.top, Spacing.xl)
                }
            case .loaded:
                if viewModel.results.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: NSLocalizedString("search.no_results.title", comment: ""),
                            message: NSLocalizedString("search.no_results.message", comment: "")
                        )
                        .padding(.top, Spacing.xl)
                    }
                } else if viewModel.viewMode == .map {
                    PropertyMapView(properties: viewModel.results)
                } else {
                    resultsList
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("search.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(NSLocalizedString("search.placeholder", comment: ""))
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(filters: viewModel.filters) { applied in
                Task { await viewModel.applyFilters(applied) }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                showingFilters = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(NSLocalizedString("search.filters", comment: ""))
                        .font(.appSubheadline)
                    if viewModel.filters.activeCount > 0 {
                        Text("\(viewModel.filters.activeCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.appOnPrimary)
                            .padding(5)
                            .background(Color.appAccent, in: Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appSurface)
                .clipShape(Capsule())
            }
            .accessibilityLabel(NSLocalizedString("a11y.filter", comment: ""))

            Spacer()

            if case .loaded = viewModel.state {
                Text(String(format: NSLocalizedString("search.results_count", comment: ""), viewModel.total))
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Picker(NSLocalizedString("search.view_mode", comment: ""), selection: $viewModel.viewMode) {
                Image(systemName: "list.bullet")
                    .accessibilityLabel(NSLocalizedString("search.view.list", comment: ""))
                    .tag(SearchViewModel.ViewMode.list)
                Image(systemName: "map")
                    .accessibilityLabel(NSLocalizedString("search.view.map", comment: ""))
                    .tag(SearchViewModel.ViewMode.map)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    Task { await viewModel.applySort(option) }
                } label: {
                    if viewModel.filters.sort == option {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(NSLocalizedString("search.sort", comment: ""))
        }
    }

    // MARK: Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.results) { property in
                    NavigationLink(value: property) {
                        PropertyRowCompact(
                            property: property,
                            isFavorite: appState.isFavorite(property),
                            onFavorite: { appState.toggleFavorite(property) }
                        )
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadMoreIfNeeded(current: property)
                    }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(Spacing.md)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable {
            await viewModel.loadFirstPage()
        }
    }

    private var skeletons: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(0..<6, id: \.self) { _ in
                    PropertyRowSkeleton()
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .disabled(true)
    }
}
