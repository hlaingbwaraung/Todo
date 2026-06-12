import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthPayload
    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthPayload
    func me() async throws -> User
}

final class AuthRepository: AuthRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthPayload {
        let envelope: APIEnvelope<AuthPayload> = try await client.send(
            Endpoints.login(email: email, password: password)
        )
        return envelope.data
    }

    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthPayload {
        let envelope: APIEnvelope<AuthPayload> = try await client.send(
            Endpoints.register(name: name, email: email, password: password, phone: phone)
        )
        return envelope.data
    }

    func me() async throws -> User {
        let envelope: APIEnvelope<User> = try await client.send(Endpoints.me())
        return envelope.data
    }
}
