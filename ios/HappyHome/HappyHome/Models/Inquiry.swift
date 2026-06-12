import Foundation

enum InquiryStatus: String, Codable {
    case new
    case inProgress = "in_progress"
    case closed

    var displayName: String {
        switch self {
        case .new: return NSLocalizedString("status.new", comment: "")
        case .inProgress: return NSLocalizedString("status.in_progress", comment: "")
        case .closed: return NSLocalizedString("status.closed", comment: "")
        }
    }
}

/// Inquiry as documented; `/api/me/inquiries` additionally exposes the
/// property's thumbnail/title — both nested and flat shapes are tolerated.
struct Inquiry: Codable, Identifiable, Hashable {
    struct PropertySummary: Codable, Hashable {
        let id: Int?
        let title: String?
        let titleJa: String?
        let thumbnailUrl: String?

        enum CodingKeys: String, CodingKey {
            case id, title
            case titleJa = "title_ja"
            case thumbnailUrl = "thumbnail_url"
        }
    }

    let id: Int
    let propertyId: Int
    let userId: Int?
    let name: String
    let email: String
    let phone: String?
    let message: String
    let status: InquiryStatus
    let createdAt: String?
    let property: PropertySummary?
    let propertyTitle: String?
    let propertyThumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId = "property_id"
        case userId = "user_id"
        case name, email, phone, message, status
        case createdAt = "created_at"
        case property
        case propertyTitle = "property_title"
        case propertyThumbnailUrl = "property_thumbnail_url"
    }

    var displayPropertyTitle: String {
        if AppConfig.prefersJapanese, let ja = property?.titleJa, !ja.isEmpty { return ja }
        if let title = property?.title ?? propertyTitle { return title }
        return "#\(propertyId)"
    }

    var thumbnailURL: URL? {
        let raw = property?.thumbnailUrl ?? propertyThumbnailUrl
        return raw.flatMap(URL.init(string:))
    }
}
