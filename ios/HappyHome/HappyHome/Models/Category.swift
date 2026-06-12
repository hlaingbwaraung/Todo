import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let nameJa: String?
    let slug: String
    let propertyCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameJa = "name_ja"
        case slug
        case propertyCount = "property_count"
    }

    var displayName: String {
        if AppConfig.prefersJapanese, let nameJa, !nameJa.isEmpty { return nameJa }
        return name
    }

    /// Best-effort SF Symbol per common category slug.
    var symbolName: String {
        switch slug {
        case "apartment", "mansion": return "building.2.fill"
        case "house", "detached": return "house.fill"
        case "office": return "briefcase.fill"
        case "studio": return "square.split.bottomrightquarter.fill"
        case "tower": return "building.fill"
        case "land": return "map.fill"
        default: return "building.columns.fill"
        }
    }
}
