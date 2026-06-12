import Foundation
import CoreLocation

enum TransactionType: String, Codable, CaseIterable, Hashable {
    case rent
    case buy

    var displayName: String {
        switch self {
        case .rent: return NSLocalizedString("property.rent", comment: "")
        case .buy: return NSLocalizedString("property.buy", comment: "")
        }
    }
}

/// Property model — field names match docs/API.md exactly via CodingKeys.
/// Fields absent in list responses (`description*`, `images`) are optional.
struct Property: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let titleJa: String?
    let description: String?
    let descriptionJa: String?
    let transactionType: TransactionType
    let status: String?
    let isFeatured: Bool?
    let price: Int
    let managementFee: Int?
    let depositMonths: Double?
    let keyMoneyMonths: Double?
    let address: String?
    let addressJa: String?
    let prefecture: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let nearestStation: String?
    let nearestStationJa: String?
    let stationWalkMin: Int?
    let layout: String?
    let sizeSqm: Double?
    let builtYear: Int?
    let buildingAgeYears: Int?
    let floor: Int?
    let totalFloors: Int?
    let categoryId: Int?
    let category: Category?
    let petAllowed: Bool?
    let parkingAvailable: Bool?
    let amenities: [String]?
    let floorPlanUrl: String?
    let agentName: String?
    let agentCompany: String?
    let agentPhone: String?
    let agentEmail: String?
    let images: [PropertyImage]?
    let thumbnailUrl: String?
    let viewCount: Int?
    var isFavorite: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case titleJa = "title_ja"
        case description
        case descriptionJa = "description_ja"
        case transactionType = "transaction_type"
        case status
        case isFeatured = "is_featured"
        case price
        case managementFee = "management_fee"
        case depositMonths = "deposit_months"
        case keyMoneyMonths = "key_money_months"
        case address
        case addressJa = "address_ja"
        case prefecture, city, latitude, longitude
        case nearestStation = "nearest_station"
        case nearestStationJa = "nearest_station_ja"
        case stationWalkMin = "station_walk_min"
        case layout
        case sizeSqm = "size_sqm"
        case builtYear = "built_year"
        case buildingAgeYears = "building_age_years"
        case floor
        case totalFloors = "total_floors"
        case categoryId = "category_id"
        case category
        case petAllowed = "pet_allowed"
        case parkingAvailable = "parking_available"
        case amenities
        case floorPlanUrl = "floor_plan_url"
        case agentName = "agent_name"
        case agentCompany = "agent_company"
        case agentPhone = "agent_phone"
        case agentEmail = "agent_email"
        case images
        case thumbnailUrl = "thumbnail_url"
        case viewCount = "view_count"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Display helpers

extension Property {
    var displayTitle: String {
        if AppConfig.prefersJapanese, let titleJa, !titleJa.isEmpty { return titleJa }
        return title
    }

    var displayDescription: String? {
        if AppConfig.prefersJapanese, let descriptionJa, !descriptionJa.isEmpty { return descriptionJa }
        return description
    }

    var displayAddress: String? {
        if AppConfig.prefersJapanese, let addressJa, !addressJa.isEmpty { return addressJa }
        return address
    }

    var displayStation: String? {
        if AppConfig.prefersJapanese, let nearestStationJa, !nearestStationJa.isEmpty { return nearestStationJa }
        return nearestStation
    }

    var featured: Bool { isFeatured ?? false }

    var priceLabel: String { price.priceLabel(for: transactionType) }

    /// Short price for map pins: rent "¥18.5万", buy "3,480万".
    var compactPriceLabel: String {
        switch transactionType {
        case .rent:
            return price.yenString
        case .buy:
            return price.manYenString
        }
    }

    var walkLabel: String? {
        guard let stationWalkMin else { return nil }
        return String(format: NSLocalizedString("property.walk_min", comment: ""), stationWalkMin)
    }

    var ageLabel: String? {
        guard let buildingAgeYears else { return nil }
        if buildingAgeYears <= 1 {
            return NSLocalizedString("property.new_built", comment: "")
        }
        return String(format: NSLocalizedString("property.age_years", comment: ""), buildingAgeYears)
    }

    var sizeLabel: String? {
        guard let sizeSqm else { return nil }
        return String(format: "%.1f㎡", sizeSqm)
    }

    var thumbnailURL: URL? {
        if let thumbnailUrl, let url = URL(string: thumbnailUrl) { return url }
        if let first = images?.sorted(by: { $0.sortOrder < $1.sortOrder }).first {
            return URL(string: first.url)
        }
        return nil
    }

    var galleryURLs: [URL] {
        let sorted = (images ?? []).sorted { $0.sortOrder < $1.sortOrder }
        let urls = sorted.compactMap { URL(string: $0.url) }
        if urls.isEmpty, let thumbnailURL { return [thumbnailURL] }
        return urls
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var amenityList: [Amenity] {
        (amenities ?? []).map { Amenity(key: $0) }
    }
}
