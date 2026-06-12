import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.appDanger)
            Text(NSLocalizedString("error.title", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(message)
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Label(NSLocalizedString("common.retry", comment: ""), systemImage: "arrow.clockwise")
                    .font(.appHeadline)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.appOnPrimary)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
