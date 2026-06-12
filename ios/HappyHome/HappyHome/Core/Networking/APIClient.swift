import Foundation

/// Error surface mapped from the documented error envelope:
/// `{ "error": { "code": "...", "message": "...", "fields": { ... } } }`
enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case decoding(Error)
    case unauthorized(message: String?)
    case server(code: String, message: String, fields: [String: String]?)
    case http(status: Int)

    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    /// Server-provided per-field validation messages, if any.
    var fieldErrors: [String: String]? {
        if case .server(_, _, let fields) = self { return fields }
        return nil
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.unknown", comment: "")
        case .transport:
            return NSLocalizedString("error.network", comment: "")
        case .decoding:
            return NSLocalizedString("error.decoding", comment: "")
        case .unauthorized(let message):
            return message ?? NSLocalizedString("error.unauthorized", comment: "")
        case .server(_, let message, _):
            return message
        case .http:
            return NSLocalizedString("error.server", comment: "")
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String
        let fields: [String: String]?
    }
    let error: Body
}

/// Minimal async/await HTTP client. Decoding uses explicit CodingKeys on every
/// model, so no key strategy is configured (matches docs/API.md exactly).
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs a request and decodes the full response body as `T`
    /// (callers pass envelope types such as `APIEnvelope<User>` or `Paginated<Property>`).
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await perform(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// For endpoints where the response body is irrelevant (e.g. device upsert).
    func sendVoid(_ endpoint: Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(_ endpoint: Endpoint) async throws -> Data {
        let request = try makeRequest(endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1)
        }
        guard (200...299).contains(http.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            if http.statusCode == 401 {
                throw APIError.unauthorized(message: envelope?.error.message)
            }
            if let envelope {
                throw APIError.server(
                    code: envelope.error.code,
                    message: envelope.error.message,
                    fields: envelope.error.fields
                )
            }
            throw APIError.http(status: http.statusCode)
        }
        return data
    }

    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: AppConfig.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try body.encoded(with: encoder)
        }
        // Bearer injection: token is read from the Keychain on every request.
        if let token = KeychainStore.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

/// Type-erasing wrapper so `Endpoint` can carry any Encodable body.
struct AnyEncodable {
    private let encodeClosure: (JSONEncoder) throws -> Data

    init<T: Encodable>(_ value: T) {
        encodeClosure = { encoder in try encoder.encode(value) }
    }

    func encoded(with encoder: JSONEncoder) throws -> Data {
        try encodeClosure(encoder)
    }
}
