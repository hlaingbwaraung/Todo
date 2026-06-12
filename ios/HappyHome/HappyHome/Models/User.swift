import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let role: String?
    let avatarUrl: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, role
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }

    /// "Tanaka Yuki" → "TY" for the avatar bubble.
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        if parts.isEmpty { return String(name.prefix(2)).uppercased() }
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

/// `{data:{token,user}}` payload returned by login/register.
struct AuthPayload: Codable {
    let token: String
    let user: User
}
