import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var recentlyViewed: RecentlyViewedStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                searchBar

                switch viewModel.state {
                case .idle, .loading:
                    loadingSkeletons
                case .failed(let message):
                    ErrorStateView(message: message) {
                        Task { await viewModel.load() }
                    }
                case .loaded:
                    content
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("HappyHome")
                    .font(.appHeadline)
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(greeting)
                .font(.appLargeTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(NSLocalizedString("home.subtitle", comment: ""))
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, Spacing.md)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return NSLocalizedString("home.greeting.morning", comment: "")
        case 12..<18: return NSLocalizedString("home.greeting.afternoon", comment: "")
        default: return NSLocalizedString("home.greeting.evening", comment: "")
        }
    }

    private var searchBar: some View {
        NavigationLink(value: PropertyFilters()) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appTextSecondary)
                Text(NSLocalizedString("home.search_placeholder", comment: ""))
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: 0, y: AppShadow.card.y)
        }
        .padding(.horizontal, Spacing.md)
        .accessibilityLabel(NSLocalizedString("tab.search", comment: ""))
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.featured.isEmpty {
            featuredSection
        }
        if !viewModel.categories.isEmpty {
            categoriesSection
        }
        if !viewModel.newListings.isEmpty {
            newListingsSection
        }
        if !recentlyViewed.items.isEmpty {
            recentlyViewedSection
        }
        if !viewModel.hasContent {
            EmptyStateView(
                icon: "house",
                title: NSLocalizedString("search.no_results.title", comment: ""),
                message: NSLocalizedString("search.no_results.message", comment: "")
            )
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: NSLocalizedString("home.featured", comment: ""))
            TabView {
                ForEach(viewModel.featured) { property in
                    NavigationLink(value: property) {
                        PropertyCard(
                            property: property,
                            isFavorite: appState.isFavorite(property),
                            onFavorite: { appState.toggleFavorite(property) }
                        )
                        .padding(.horizontal, Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 320)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: NSLocalizedString("home.categories", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.categories) { category in
                        NavigationLink(value: filters(for: category)) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: category.symbolName)
                                    .font(.caption)
                                    .foregroundStyle(Color.appAccent)
                                Text(category.displayName)
                                    .font(.appSubheadline)
                                    .foregroundStyle(Color.appTextPrimary)
                                if let count = category.propertyCount {
                                    Text("\(count)")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.appSurface)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func filters(for category: Category) -> PropertyFilters {
        var filters = PropertyFilters()
        filters.categorySlug = category.slug
        return filters
    }

    private var newListingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: NSLocalizedString("home.new_listings", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.newListings) { property in
                        NavigationLink(value: property) {
                            PropertyCard(
                                property: property,
                                isFavorite: appState.isFavorite(property),
                                onFavorite: { appState.toggleFavorite(property) },
                                width: 280
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: NSLocalizedString("home.recently_viewed", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(recentlyViewed.items) { property in
                        NavigationLink(value: property) {
                            PropertyCard(
                                property: property,
                                isFavorite: appState.isFavorite(property),
                                onFavorite: { appState.toggleFavorite(property) },
                                width: 280
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private var loadingSkeletons: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            PropertyCardSkeleton()
                .padding(.horizontal, Spacing.md)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    PropertyCardSkeleton(width: 280)
                    PropertyCardSkeleton(width: 280)
                }
                .padding(.horizontal, Spacing.md)
            }
            .disabled(true)
        }
    }
}
