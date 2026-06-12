import SwiftUI

/// Selectable pill used for layout/category/time-slot selection.
struct FilterChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }
                Text(title)
                    .font(.appSubheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.appOnPrimary : Color.appTextPrimary)
            .background(isSelected ? Color.appPrimary : Color.appSurfaceSecondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
