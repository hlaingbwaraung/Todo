import Foundation

extension Int {
    /// "¥185,000"
    var yenString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let grouped = formatter.string(from: NSNumber(value: self)) ?? String(self)
        return "¥" + grouped
    }

    /// Sale price in 万円 for Japanese ("3,480万円"); full yen for other locales.
    var manYenString: String {
        guard AppConfig.prefersJapanese else { return yenString }
        let man = Double(self) / 10_000.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = self % 10_000 == 0 ? 0 : 1
        let grouped = formatter.string(from: NSNumber(value: man)) ?? String(Int(man))
        return grouped + "万円"
    }

    /// Price label for a transaction type: rent "¥185,000/月", buy "3,480万円".
    func priceLabel(for transactionType: TransactionType) -> String {
        switch transactionType {
        case .rent:
            return yenString + NSLocalizedString("price.per_month_suffix", comment: "")
        case .buy:
            return manYenString
        }
    }
}
