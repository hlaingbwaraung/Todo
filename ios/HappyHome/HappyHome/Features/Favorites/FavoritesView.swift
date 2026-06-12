import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var compareStore: CompareStore
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var showingLogin = false

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                loggedOutState
            } else {
                switch viewModel.state {
                case .idle, .loading:
                    skeletons
                case .failed(let message):
                    ScrollView {
                        ErrorStateView(message: message) {
                            Task { await viewModel.load(appState: appState) }
                        }
                        .padding(.top, Spacing.xl)
                    }
                case .loaded:
                    if appState.favoriteProperties.isEmpty {
                        emptyState
                    } else {
                        favoritesList
                    }
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("favorites.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CompareView()
                } label: {
                    Image(systemName: compareStore.items.isEmpty
                          ? "rectangle.split.2x1"
                          : "rectangle.split.2x1.fill")
                }
                .accessibilityLabel(NSLocalizedString("compare.title", comment: ""))
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .task(id: appState.isAuthenticated) {
            if appState.isAuthenticated {
                await viewModel.loadIfNeeded(appState: appState)
            }
        }
    }

    // MARK: States

    private var loggedOutState: some View {
        ScrollView {
            EmptyStateView(
                icon: "heart",
                title: NSLocalizedString("favorites.logged_out.title", comment: ""),
                message: NSLocalizedString("favorites.logged_out.message", comment: ""),
                actionTitle: NSLocalizedString("auth.login", comment: ""),
                action: { showingLogin = true }
            )
            .padding(.top, Spacing.xl)
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "heart",
                title: NSLocalizedString("favorites.empty.title", comment: ""),
                message: NSLocalizedString("favorites.empty.message", comment: "")
            )
            .padding(.top, Spacing.xl)
        }
        .refreshable {
            await viewModel.load(appState: appState)
        }
    }

    private var favoritesList: some View {
        List {
            ForEach(appState.favoriteProperties) { property in
                ZStack {
                    PropertyRowCompact(
                        property: property,
                        isFavorite: appState.isFavorite(property),
                        onFavorite: { appState.toggleFavorite(property) }
                    )
                    NavigationLink(value: property) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs, leading: Spacing.md,
                    bottom: Spacing.xs, trailing: Spacing.md
                ))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        appState.toggleFavorite(property)
                    } label: {
                        Label(NSLocalizedString("favorites.remove", comment: ""), systemImage: "heart.slash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.load(appState: appState)
        }
    }

    private var skeletons: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    PropertyRowSkeleton()
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .disabled(true)
    }
}
