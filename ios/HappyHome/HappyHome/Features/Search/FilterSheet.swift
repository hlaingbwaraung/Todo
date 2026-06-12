import SwiftUI

/// Full filter editor; edits a draft and reports back on apply.
struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PropertyFilters
    @State private var minPriceText: String
    @State private var maxPriceText: String
    @State private var categories: [Category] = []

    private let onApply: (PropertyFilters) -> Void
    private let repository: PropertyRepositoryProtocol

    init(
        filters: PropertyFilters,
        repository: PropertyRepositoryProtocol = PropertyRepository(),
        onApply: @escaping (PropertyFilters) -> Void
    ) {
        _draft = State(initialValue: filters)
        _minPriceText = State(initialValue: filters.minPrice.map(String.init) ?? "")
        _maxPriceText = State(initialValue: filters.maxPrice.map(String.init) ?? "")
        self.repository = repository
        self.onApply = onApply
    }

    private var sliderUpperBound: Double {
        draft.transactionType == .buy ? 300_000_000 : 1_000_000
    }

    private var sliderStep: Double {
        draft.transactionType == .buy ? 5_000_000 : 10_000
    }

    /// Slider drives the max-price text field.
    private var maxPriceSliderBinding: Binding<Double> {
        Binding(
            get: {
                let value = Double(Int(maxPriceText) ?? Int(sliderUpperBound))
                return min(max(value, 0), sliderUpperBound)
            },
            set: { newValue in
                maxPriceText = newValue >= sliderUpperBound ? "" : String(Int(newValue))
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                transactionSection
                priceSection
                layoutSection
                sizeAndAgeSection
                stationSection
                optionsSection
                categorySection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(NSLocalizedString("filter.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("filter.reset", comment: "")) {
                        withAnimation {
                            draft = PropertyFilters()
                            minPriceText = ""
                            maxPriceText = ""
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("common.close", comment: "")) {
                        dismiss()
                    }
                    .accessibilityLabel(NSLocalizedString("common.close", comment: ""))
                }
            }
            .safeAreaInset(edge: .bottom) {
                applyButton
            }
            .task {
                if let cached = repository.cachedCategories() {
                    categories = cached
                }
                if let fresh = try? await repository.categories() {
                    categories = fresh
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Sections

    private var transactionSection: some View {
        Section(NSLocalizedString("filter.transaction_type", comment: "")) {
            Picker(NSLocalizedString("filter.transaction_type", comment: ""), selection: $draft.transactionType) {
                Text(NSLocalizedString("filter.all", comment: "")).tag(TransactionType?.none)
                Text(NSLocalizedString("property.rent", comment: "")).tag(TransactionType?.some(.rent))
                Text(NSLocalizedString("property.buy", comment: "")).tag(TransactionType?.some(.buy))
            }
            .pickerStyle(.segmented)
        }
    }

    private var priceSection: some View {
        Section(NSLocalizedString("filter.price_range", comment: "")) {
            HStack {
                TextField(NSLocalizedString("filter.min_price", comment: ""), text: $minPriceText)
                    .keyboardType(.numberPad)
                Text("〜")
                    .foregroundStyle(Color.appTextSecondary)
                TextField(NSLocalizedString("filter.max_price", comment: ""), text: $maxPriceText)
                    .keyboardType(.numberPad)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Slider(value: maxPriceSliderBinding, in: 0...sliderUpperBound, step: sliderStep)
                Text(maxPriceText.isEmpty
                     ? NSLocalizedString("filter.no_limit", comment: "")
                     : (Int(maxPriceText) ?? 0).yenString)
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private var layoutSection: some View {
        Section(NSLocalizedString("filter.layout", comment: "")) {
            FlowLayoutChips(
                options: PropertyFilters.layoutOptions,
                selection: $draft.layouts
            )
        }
    }

    private var sizeAndAgeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(NSLocalizedString("filter.min_size", comment: ""))
                    .font(.appSubheadline)
                Slider(
                    value: Binding(
                        get: { draft.minSize ?? 0 },
                        set: { draft.minSize = $0 <= 0 ? nil : $0 }
                    ),
                    in: 0...150,
                    step: 5
                )
                Text(draft.minSize.map { String(format: "%.0f㎡〜", $0) }
                     ?? NSLocalizedString("filter.no_limit", comment: ""))
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Picker(NSLocalizedString("filter.max_age", comment: ""), selection: $draft.maxAge) {
                Text(NSLocalizedString("filter.no_limit", comment: "")).tag(Int?.none)
                ForEach([1, 5, 10, 15, 20, 30], id: \.self) { years in
                    Text(String(format: NSLocalizedString("filter.within_years", comment: ""), years))
                        .tag(Int?.some(years))
                }
            }
        } header: {
            Text(NSLocalizedString("filter.size", comment: ""))
        }
    }

    private var stationSection: some View {
        Section(NSLocalizedString("filter.max_walk", comment: "")) {
            Picker(NSLocalizedString("filter.max_walk", comment: ""), selection: $draft.maxWalkMin) {
                Text(NSLocalizedString("filter.no_limit", comment: "")).tag(Int?.none)
                ForEach([5, 10, 15, 20], id: \.self) { minutes in
                    Text(String(format: NSLocalizedString("filter.within_walk", comment: ""), minutes))
                        .tag(Int?.some(minutes))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var optionsSection: some View {
        Section(NSLocalizedString("filter.options", comment: "")) {
            Toggle(NSLocalizedString("filter.pet_allowed", comment: ""), isOn: $draft.petAllowed)
            Toggle(NSLocalizedString("filter.parking", comment: ""), isOn: $draft.parking)
        }
    }

    private var categorySection: some View {
        Section(NSLocalizedString("filter.category", comment: "")) {
            Picker(NSLocalizedString("filter.category", comment: ""), selection: $draft.categorySlug) {
                Text(NSLocalizedString("filter.all", comment: "")).tag(String?.none)
                ForEach(categories) { category in
                    Text(category.displayName).tag(String?.some(category.slug))
                }
            }
        }
    }

    private var applyButton: some View {
        PrimaryButton(title: applyTitle) {
            var applied = draft
            applied.minPrice = Int(minPriceText)
            applied.maxPrice = Int(maxPriceText)
            onApply(applied)
            dismiss()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.thinMaterial)
    }

    private var applyTitle: String {
        var current = draft
        current.minPrice = Int(minPriceText)
        current.maxPrice = Int(maxPriceText)
        let count = current.activeCount
        if count > 0 {
            return String(format: NSLocalizedString("filter.apply_count", comment: ""), count)
        }
        return NSLocalizedString("filter.apply", comment: "")
    }
}

/// Simple wrapping chip group for the layout multi-select.
private struct FlowLayoutChips: View {
    let options: [String]
    @Binding var selection: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: Spacing.sm)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
            ForEach(options, id: \.self) { option in
                FilterChip(
                    title: option,
                    isSelected: selection.contains(option)
                ) {
                    if selection.contains(option) {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
