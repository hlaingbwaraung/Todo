import Foundation

/// Amenity keys from docs/API.md, with localized display names and SF Symbols.
/// Unknown server keys degrade gracefully to a humanized label.
enum Amenity: Hashable {
    case autolock
    case balcony
    case airConditioner
    case bathToiletSeparate
    case deliveryBox
    case internetFree
    case systemKitchen
    case floorHeating
    case other(String)

    init(key: String) {
        switch key {
        case "autolock": self = .autolock
        case "balcony": self = .balcony
        case "air_conditioner": self = .airConditioner
        case "bath_toilet_separate": self = .bathToiletSeparate
        case "delivery_box": self = .deliveryBox
        case "internet_free": self = .internetFree
        case "system_kitchen": self = .systemKitchen
        case "floor_heating": self = .floorHeating
        default: self = .other(key)
        }
    }

    var displayName: String {
        switch self {
        case .autolock: return NSLocalizedString("amenity.autolock", comment: "")
        case .balcony: return NSLocalizedString("amenity.balcony", comment: "")
        case .airConditioner: return NSLocalizedString("amenity.air_conditioner", comment: "")
        case .bathToiletSeparate: return NSLocalizedString("amenity.bath_toilet_separate", comment: "")
        case .deliveryBox: return NSLocalizedString("amenity.delivery_box", comment: "")
        case .internetFree: return NSLocalizedString("amenity.internet_free", comment: "")
        case .systemKitchen: return NSLocalizedString("amenity.system_kitchen", comment: "")
        case .floorHeating: return NSLocalizedString("amenity.floor_heating", comment: "")
        case .other(let key):
            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var symbolName: String {
        switch self {
        case .autolock: return "lock.shield.fill"
        case .balcony: return "sun.max.fill"
        case .airConditioner: return "wind"
        case .bathToiletSeparate: return "shower.fill"
        case .deliveryBox: return "shippingbox.fill"
        case .internetFree: return "wifi"
        case .systemKitchen: return "fork.knife"
        case .floorHeating: return "flame.fill"
        case .other: return "checkmark.circle.fill"
        }
    }
}
