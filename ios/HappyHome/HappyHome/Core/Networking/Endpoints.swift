import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var body: AnyEncodable?
}

// MARK: - Request bodies (field names match docs/API.md exactly)

struct LoginBody: Encodable {
    let email: String
    let password: String
}

struct RegisterBody: Encodable {
    let name: String
    let email: String
    let password: String
    let phone: String?
}

struct FavoriteBody: Encodable {
    let propertyId: Int

    enum CodingKeys: String, CodingKey {
        case propertyId = "property_id"
    }
}

struct InquiryBody: Encodable {
    let propertyId: Int
    let name: String
    let email: String
    let phone: String?
    let message: String

    enum CodingKeys: String, CodingKey {
        case propertyId = "property_id"
        case name, email, phone, message
    }
}

struct ReservationBody: Encodable {
    let propertyId: Int
    let name: String
    let email: String
    let phone: String?
    let preferredDate: String   // "YYYY-MM-DD"
    let preferredTime: String   // "HH:mm"
    let message: String?

    enum CodingKeys: String, CodingKey {
        case propertyId = "property_id"
        case name, email, phone
        case preferredDate = "preferred_date"
        case preferredTime = "preferred_time"
        case message
    }
}

struct DeviceBody: Encodable {
    let deviceToken: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case platform
    }
}

// MARK: - Endpoint catalogue

enum Endpoints {
    // Auth
    static func login(email: String, password: String) -> Endpoint {
        Endpoint(path: "/api/auth/login", method: .post,
                 body: AnyEncodable(LoginBody(email: email, password: password)))
    }

    static func register(name: String, email: String, password: String, phone: String?) -> Endpoint {
        Endpoint(path: "/api/auth/register", method: .post,
                 body: AnyEncodable(RegisterBody(name: name, email: email, password: password, phone: phone)))
    }

    static func me() -> Endpoint {
        Endpoint(path: "/api/auth/me")
    }

    // Properties
    static func properties(query: [URLQueryItem]) -> Endpoint {
        Endpoint(path: "/api/properties", queryItems: query)
    }

    static func property(id: Int) -> Endpoint {
        Endpoint(path: "/api/properties/\(id)")
    }

    static func similarProperties(id: Int) -> Endpoint {
        Endpoint(path: "/api/properties/\(id)/similar")
    }

    static func categories() -> Endpoint {
        Endpoint(path: "/api/categories")
    }

    // Favorites
    static func favorites() -> Endpoint {
        Endpoint(path: "/api/favorites")
    }

    static func addFavorite(propertyId: Int) -> Endpoint {
        Endpoint(path: "/api/favorites", method: .post,
                 body: AnyEncodable(FavoriteBody(propertyId: propertyId)))
    }

    static func removeFavorite(propertyId: Int) -> Endpoint {
        Endpoint(path: "/api/favorites/\(propertyId)", method: .delete)
    }

    // Inquiries & reservations
    static func createInquiry(_ body: InquiryBody) -> Endpoint {
        Endpoint(path: "/api/inquiries", method: .post, body: AnyEncodable(body))
    }

    static func createReservation(_ body: ReservationBody) -> Endpoint {
        Endpoint(path: "/api/reservations", method: .post, body: AnyEncodable(body))
    }

    static func myInquiries() -> Endpoint {
        Endpoint(path: "/api/me/inquiries")
    }

    static func myReservations() -> Endpoint {
        Endpoint(path: "/api/me/reservations")
    }

    // Devices
    static func registerDevice(token: String) -> Endpoint {
        Endpoint(path: "/api/devices", method: .post,
                 body: AnyEncodable(DeviceBody(deviceToken: token, platform: "ios")))
    }
}
