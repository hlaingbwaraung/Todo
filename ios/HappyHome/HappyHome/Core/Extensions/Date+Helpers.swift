import Foundation

extension Date {
    /// "YYYY-MM-DD" — the wire format for `preferred_date`.
    var apiDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

extension String {
    /// Parses an ISO-8601 API timestamp (with or without fractional seconds).
    var apiDate: Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: self) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: self)
    }

    /// Human readable medium date for ISO timestamps; falls back to the raw value.
    var displayDate: String {
        guard let date = apiDate else { return self }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
