import Foundation

/// Global app configuration. The API base URL can be overridden at runtime
/// (Settings screen) via the "api_base_url" UserDefaults key for dev/QA builds.
enum AppConfig {
    static let baseURLDefaultsKey = "api_base_url"
    static let defaultBaseURLString = "http://localhost:8000"

    static var baseURLString: String {
        let stored = UserDefaults.standard.string(forKey: baseURLDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored, !stored.isEmpty { return stored }
        return defaultBaseURLString
    }

    static var baseURL: URL {
        URL(string: baseURLString) ?? URL(string: defaultBaseURLString)!
    }

    static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// True when the user's preferred language is Japanese; used to pick
    /// the `*_ja` fields from the API payloads.
    static var prefersJapanese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
    }
}
