import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(Color.appOnPrimary)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.appHeadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color.appOnPrimary)
            .background(Color.appPrimary.opacity(isEnabled ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
    }
}
