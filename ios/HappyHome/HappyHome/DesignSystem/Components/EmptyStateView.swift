import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.appTextSecondary)
            Text(title)
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(message)
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.appHeadline)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color.appOnPrimary)
                        .background(Color.appPrimary)
                        .clipShape(Capsule())
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
