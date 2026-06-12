import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .withPropertyDestinations()
            }
            .tabItem {
                Label(NSLocalizedString("tab.home", comment: ""), systemImage: "house.fill")
            }

            NavigationStack {
                SearchView()
                    .withPropertyDestinations()
            }
            .tabItem {
                Label(NSLocalizedString("tab.search", comment: ""), systemImage: "magnifyingglass")
            }

            NavigationStack {
                FavoritesView()
                    .withPropertyDestinations()
            }
            .tabItem {
                Label(NSLocalizedString("tab.favorites", comment: ""), systemImage: "heart.fill")
            }
            .badge(appState.favoriteIds.isEmpty ? 0 : appState.favoriteIds.count)

            NavigationStack {
                ProfileView()
                    .withPropertyDestinations()
            }
            .tabItem {
                Label(NSLocalizedString("tab.profile", comment: ""), systemImage: "person.fill")
            }
        }
    }
}

// MARK: - Shared navigation destinations

/// Value-based destinations shared by every tab's NavigationStack.
struct PropertyDestinationsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Property.self) { property in
                PropertyDetailView(property: property)
            }
            .navigationDestination(for: PropertyFilters.self) { filters in
                SearchView(initialFilters: filters)
            }
    }
}

extension View {
    func withPropertyDestinations() -> some View {
        modifier(PropertyDestinationsModifier())
    }
}
