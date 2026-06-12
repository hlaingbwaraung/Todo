import Foundation

/// AppState owns the favorite set (so hearts stay in sync app-wide);
/// this view model only tracks the screen's load lifecycle.
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var state: LoadState = .idle

    func loadIfNeeded(appState: AppState) async {
        guard state == .idle else { return }
        await load(appState: appState)
    }

    func load(appState: AppState) async {
        guard appState.isAuthenticated else {
            state = .idle
            return
        }
        state = appState.favoriteProperties.isEmpty ? .loading : .loaded
        await appState.refreshFavorites()
        state = .loaded
    }
}
