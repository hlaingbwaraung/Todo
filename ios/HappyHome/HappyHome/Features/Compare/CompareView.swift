import SwiftUI

/// Side-by-side comparison of the up-to-3 properties held in CompareStore.
struct CompareView: View {
    @EnvironmentObject private var compareStore: CompareStore

    private let labelWidth: CGFloat = 88

    var body: some View {
        Group {
            if compareStore.items.isEmpty {
                emptyState
            } else {
                comparisonTable
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("compare.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !compareStore.items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("compare.clear", comment: "")) {
                        compareStore.clear()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "rectangle.split.2x1",
                title: NSLocalizedString("compare.empty.title", comment: ""),
                message: NSLocalizedString("compare.empty.message", comment: "")
            )
            .padding(.top, Spacing.xl)
        }
    }

    // MARK: Table

    private var comparisonTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                    .padding(.bottom, Spacing.sm)

                row(NSLocalizedString("compare.price", comment: "")) { $0.priceLabel }
                row(NSLocalizedString("compare.layout", comment: "")) { $0.layout ?? "—" }
                row(NSLocalizedString("compare.size", comment: "")) { $0.sizeLabel ?? "—" }
                row(NSLocalizedString("compare.age", comment: "")) { $0.ageLabel ?? "—" }
                row(NSLocalizedString("compare.walk", comment: "")) { $0.walkLabel ?? "—" }
                row(NSLocalizedString("compare.pet", comment: "")) { boolMark($0.petAllowed) }
                row(NSLocalizedString("compare.parking", comment: "")) { boolMark($0.parkingAvailable) }
                row(NSLocalizedString("compare.management_fee", comment: "")) {
                    $0.managementFee.map(\.yenString) ?? "—"
                }
                row(NSLocalizedString("compare.deposit", comment: "")) { monthsMark($0.depositMonths) }
                row(NSLocalizedString("compare.key_money", comment: "")) { monthsMark($0.keyMoneyMonths) }
                row(NSLocalizedString("compare.amenity_count", comment: "")) { "\($0.amenityList.count)" }
            }
            .padding(Spacing.md)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Color.clear
                .frame(width: labelWidth, height: 1)

            ForEach(compareStore.items) { property in
                NavigationLink(value: property) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ZStack(alignment: .topTrailing) {
                            CachedAsyncImage(url: property.thumbnailURL)
                                .frame(height: 76)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: Radii.chip, style: .continuous))

                            Button {
                                compareStore.remove(property)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white, Color.black.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                            .accessibilityLabel(NSLocalizedString("compare.remove", comment: ""))
                        }
                        Text(property.displayTitle)
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func row(_ label: String, value: (Property) -> String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: labelWidth, alignment: .leading)

            ForEach(compareStore.items) { property in
                Text(value(property))
                    .font(.appSubheadline.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
    }

    private func boolMark(_ value: Bool?) -> String {
        value == true
            ? NSLocalizedString("compare.yes", comment: "")
            : NSLocalizedString("compare.no", comment: "")
    }

    private func monthsMark(_ months: Double?) -> String {
        guard let months, months > 0 else {
            return NSLocalizedString("common.none", comment: "")
        }
        return String(format: NSLocalizedString("detail.months_value", comment: ""), months)
    }
}
