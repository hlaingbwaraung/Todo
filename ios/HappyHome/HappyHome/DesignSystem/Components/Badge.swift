import SwiftUI

enum BadgeStyle {
    case featured       // gold
    case neutral        // navy outline-ish
    case success
    case warning
    case danger

    var background: Color {
        switch self {
        case .featured: return .appAccent
        case .neutral: return .appSurfaceSecondary
        case .success: return .appSuccess.opacity(0.15)
        case .warning: return .appAccent.opacity(0.18)
        case .danger: return .appDanger.opacity(0.15)
        }
    }

    var foreground: Color {
        switch self {
        case .featured: return Color(light: UIColor(hex: 0x3A2E00), dark: UIColor(hex: 0x0B1622))
        case .neutral: return .appTextPrimary
        case .success: return .appSuccess
        case .warning: return Color(light: UIColor(hex: 0x8A6D0B), dark: UIColor(hex: 0xE1B84A))
        case .danger: return .appDanger
        }
    }
}

struct Badge: View {
    let text: String
    var style: BadgeStyle = .neutral
    var systemImage: String?

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(style.foreground)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: Radii.chip, style: .continuous))
    }
}

extension Badge {
    static func forInquiryStatus(_ status: InquiryStatus) -> Badge {
        switch status {
        case .new: return Badge(text: status.displayName, style: .warning)
        case .inProgress: return Badge(text: status.displayName, style: .neutral)
        case .closed: return Badge(text: status.displayName, style: .success)
        }
    }

    static func forReservationStatus(_ status: ReservationStatus) -> Badge {
        switch status {
        case .pending: return Badge(text: status.displayName, style: .warning)
        case .confirmed: return Badge(text: status.displayName, style: .success)
        case .cancelled: return Badge(text: status.displayName, style: .danger)
        case .completed: return Badge(text: status.displayName, style: .neutral)
        }
    }
}
