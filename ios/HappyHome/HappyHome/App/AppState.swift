import Foundation
import SwiftUI

/// App-wide session state: current user, auth token (Keychain-backed) and the
/// favorite-id set used for instant heart toggling everywhere in the UI.
@MainActor
final class AppState: ObservableObject {
    @Published var user: User?
    @Published var favoriteIds: Set<Int> = []
    @Published var favoriteProperties: [Property] = []

    let recentlyViewed = RecentlyViewedStore()
    let compareStore = CompareStore()

    private let authRepository: AuthRepositoryProtocol
    private let favoriteRepository: FavoriteRepositoryProtocol

    var isAuthenticated: Bool { user != nil && KeychainStore.shared.token != nil }

    init(
        authRepository: AuthRepositoryProtocol = AuthRepository(),
        favoriteRepository: FavoriteRepositoryProtocol = FavoriteRepository()
    ) {
        self.authRepository = authRepository
        self.favoriteRepository = favoriteRepository
    }

    /// Restores the session at launch when a token is stored.
    func bootstrap() async {
        guard KeychainStore.shared.token != nil else { return }
        do {
            user = try await authRepository.me()
            await refreshFavorites()
        } catch let error as APIError where error.isUnauthorized {
            sessionDidEnd()
        } catch {
            // Offline launch: keep the token and try again later.
        }
    }

    func sessionDidStart(token: String, user: User) {
        KeychainStore.shared.token = token
        self.user = user
        Task { await refreshFavorites() }
        PushService.shared.requestAuthorizationAndRegister()
    }

    func sessionDidEnd() {
        KeychainStore.shared.token = nil
        user = nil
        favoriteIds = []
        favoriteProperties = []
    }

    func refreshFavorites() async {
        guard isAuthenticated else { return }
        do {
            let list = try await favoriteRepository.list()
            favoriteProperties = list
            favoriteIds = Set(list.map(\.id))
        } catch {
            // Keep the last known set on failure.
        }
    }

    func isFavorite(_ property: Property) -> Bool {
        favoriteIds.contains(property.id)
    }

    /// Optimistic toggle with rollback on API failure.
    func toggleFavorite(_ property: Property) {
        guard isAuthenticated else { return }
        Haptics.light()
        let wasFavorite = favoriteIds.contains(property.id)
        withAnimation(.spring(duration: 0.3)) {
            if wasFavorite {
                favoriteIds.remove(property.id)
                favoriteProperties.removeAll { $0.id == property.id }
            } else {
                favoriteIds.insert(property.id)
                favoriteProperties.insert(property, at: 0)
            }
        }
        Task {
            do {
                if wasFavorite {
                    try await favoriteRepository.remove(propertyId: property.id)
                } else {
                    try await favoriteRepository.add(propertyId: property.id)
                }
            } catch {
                // Roll back the optimistic change.
                withAnimation {
                    if wasFavorite {
                        self.favoriteIds.insert(property.id)
                        self.favoriteProperties.insert(property, at: 0)
                    } else {
                        self.favoriteIds.remove(property.id)
                        self.favoriteProperties.removeAll { $0.id == property.id }
                    }
                }
            }
        }
    }
}
