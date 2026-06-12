import SwiftUI

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.appHeadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color.appPrimary)
            .background(
                RoundedRectangle(cornerRadius: Radii.control, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(isEnabled ? 1 : 0.4), lineWidth: 1.5)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}
