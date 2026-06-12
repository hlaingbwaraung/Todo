import SwiftUI

extension View {
    /// Standard card chrome used across the app.
    func cardStyle(cornerRadius: CGFloat = Radii.card) -> some View {
        self
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius,
                    x: 0, y: AppShadow.card.y)
    }

    /// Applies a transformation conditionally while keeping the chain readable.
    @ViewBuilder
    func ifCondition<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Centralized haptics helpers.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

/// Shared view-model loading state.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
