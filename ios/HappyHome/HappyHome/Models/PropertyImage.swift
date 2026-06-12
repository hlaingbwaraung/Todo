import Foundation

struct PropertyImage: Codable, Identifiable, Hashable {
    let id: Int
    let url: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, url
        case sortOrder = "sort_order"
    }
}
