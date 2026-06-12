import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.appSubheadline.weight(.medium))
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}
