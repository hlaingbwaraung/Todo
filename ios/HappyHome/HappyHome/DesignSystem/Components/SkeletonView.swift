import SwiftUI

/// Animated shimmer placeholder block.
struct SkeletonView: View {
    var cornerRadius: CGFloat = Radii.chip

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.appSurfaceSecondary)
            .shimmering()
    }
}

/// Moving highlight overlay used for all skeleton states.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .offset(x: proxy.size.width * phase)
                }
                .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.6
                }
            }
            .accessibilityHidden(true)
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Placeholder matching the PropertyCard layout.
struct PropertyCardSkeleton: View {
    var width: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonView(cornerRadius: Radii.card)
                .frame(height: 160)
            SkeletonView()
                .frame(width: 110, height: 22)
            SkeletonView()
                .frame(height: 14)
            SkeletonView()
                .frame(width: 140, height: 14)
        }
        .padding(Spacing.sm)
        .frame(width: width)
        .cardStyle()
    }
}

/// Placeholder matching PropertyRowCompact.
struct PropertyRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            SkeletonView(cornerRadius: Radii.control)
                .frame(width: 96, height: 80)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonView().frame(width: 90, height: 18)
                SkeletonView().frame(height: 12)
                SkeletonView().frame(width: 120, height: 12)
            }
        }
        .padding(Spacing.sm)
        .cardStyle()
    }
}
