import SwiftUI

struct AmenityTag: View {
    let amenity: Amenity

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: amenity.symbolName)
                .font(.caption)
                .foregroundStyle(Color.appAccent)
            Text(amenity.displayName)
                .font(.appFootnote)
                .foregroundStyle(Color.appTextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.appSurfaceSecondary)
        .clipShape(Capsule())
    }
}
