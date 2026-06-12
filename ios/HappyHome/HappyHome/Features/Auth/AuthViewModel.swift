import Foundation

/// Shared login/registration logic. On success the session is handed to
/// AppState (token → Keychain, user → published state).
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol = AuthRepository()) {
        self.repository = repository
    }

    /// Returns true on success so the presenting view can dismiss.
    func login(email: String, password: String, appState: AppState) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let payload = try await repository.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            appState.sessionDidStart(token: payload.token, user: payload.user)
            Haptics.success()
            return true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Returns true on success so the presenting view can dismiss.
    func register(
        name: String,
        email: String,
        password: String,
        phone: String?,
        appState: AppState
    ) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let payload = try await repository.register(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                phone: phone
            )
            appState.sessionDidStart(token: payload.token, user: payload.user)
            Haptics.success()
            return true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - Lightweight client-side validation helpers

extension String {
    /// Cheap "looks like an email" check; the server remains the authority.
    var isLikelyEmail: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5, !trimmed.contains(" ") else { return false }
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2 else { return false }
        return parts[1].contains(".")
    }
}
