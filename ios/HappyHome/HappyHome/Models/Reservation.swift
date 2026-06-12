import Foundation

enum ReservationStatus: String, Codable {
    case pending
    case confirmed
    case cancelled
    case completed

    var displayName: String {
        switch self {
        case .pending: return NSLocalizedString("status.pending", comment: "")
        case .confirmed: return NSLocalizedString("status.confirmed", comment: "")
        case .cancelled: return NSLocalizedString("status.cancelled", comment: "")
        case .completed: return NSLocalizedString("status.completed", comment: "")
        }
    }
}

struct Reservation: Codable, Identifiable, Hashable {
    let id: Int
    let propertyId: Int
    let userId: Int?
    let name: String
    let email: String
    let phone: String?
    let preferredDate: String   // "YYYY-MM-DD"
    let preferredTime: String   // "HH:mm"
    let message: String?
    let status: ReservationStatus
    let createdAt: String?
    let property: Inquiry.PropertySummary?
    let propertyTitle: String?
    let propertyThumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId = "property_id"
        case userId = "user_id"
        case name, email, phone
        case preferredDate = "preferred_date"
        case preferredTime = "preferred_time"
        case message, status
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
