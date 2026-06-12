import Foundation

enum SortOption: String, CaseIterable, Hashable {
    case newest
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"
    case sizeDesc = "size_desc"

    var displayName: String {
        switch self {
        case .newest: return NSLocalizedString("search.sort.newest", comment: "")
        case .priceAsc: return NSLocalizedString("search.sort.price_asc", comment: "")
        case .priceDesc: return NSLocalizedString("search.sort.price_desc", comment: "")
        case .sizeDesc: return NSLocalizedString("search.sort.size_desc", comment: "")
        }
    }
}

/// All supported `GET /api/properties` filters (see docs/API.md).
struct PropertyFilters: Hashable {
    var query: String = ""
    var transactionType: TransactionType?
    var minPrice: Int?
    var maxPrice: Int?
    var layouts: Set<String> = []
    var minSize: Double?
    var maxSize: Double?
    var maxAge: Int?
    var maxWalkMin: Int?
    var petAllowed: Bool = false
    var parking: Bool = false
    var categorySlug: String?
    var featuredOnly: Bool = false
    var sort: SortOption = .newest

    static let layoutOptions = ["1R", "1K", "1DK", "1LDK", "2K", "2DK", "2LDK", "3LDK", "4LDK+"]

    /// Number of active filters shown on the filter button / apply CTA.
    var activeCount: Int {
        var count = 0
        if transactionType != nil { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if !layouts.isEmpty { count += 1 }
        if minSize != nil || maxSize != nil { count += 1 }
        if maxAge != nil { count += 1 }
        if maxWalkMin != nil { count += 1 }
        if petAllowed { count += 1 }
        if parking { count += 1 }
        if categorySlug != nil { count += 1 }
        return count
    }

    func queryItems(page: Int, perPage: Int = 20) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "q", value: trimmed))
        }
        if let transactionType {
            items.append(URLQueryItem(name: "transaction_type", value: transactionType.rawValue))
        }
        if let minPrice {
            items.append(URLQueryItem(name: "min_price", value: String(minPrice)))
        }
        if let maxPrice {
            items.append(URLQueryItem(name: "max_price", value: String(maxPrice)))
        }
        if !layouts.isEmpty {
            items.append(URLQueryItem(name: "layout", value: layouts.sorted().joined(separator: ",")))
        }
        if let minSize {
            items.append(URLQueryItem(name: "min_size", value: String(Int(minSize))))
        }
        if let maxSize {
            items.append(URLQueryItem(name: "max_size", value: String(Int(maxSize))))
        }
        if let maxAge {
            items.append(URLQueryItem(name: "max_age", value: String(maxAge)))
        }
        if let maxWalkMin {
            items.append(URLQueryItem(name: "max_walk_min", value: String(maxWalkMin)))
        }
        if petAllowed {
            items.append(URLQueryItem(name: "pet_allowed", value: "1"))
        }
        if parking {
            items.append(URLQueryItem(name: "parking", value: "1"))
        }
        if let categorySlug {
            items.append(URLQueryItem(name: "category", value: categorySlug))
        }
        if featuredOnly {
            items.append(URLQueryItem(name: "featured", value: "1"))
        }
        items.append(URLQueryItem(name: "sort", value: sort.rawValue))
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "per_page", value: String(perPage)))
        return items
    }
}
