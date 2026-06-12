import Foundation

/// `{ "data": { ... } }`
struct APIEnvelope<T: Codable>: Codable {
    let data: T
}

/// `{ "data": [ ... ], "meta": { ... } }`
struct Paginated<T: Codable>: Codable {
    let data: [T]
    let meta: PageMeta?
}

struct PageMeta: Codable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case total
        case totalPages = "total_pages"
    }
}
