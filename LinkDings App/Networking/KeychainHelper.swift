import Foundation

enum KeychainHelper {
    static let appGroupID = "group.com.mazjap.LinkDings-Client"
    private static let instanceURLKey = "instanceURL"
    private static let apiKeyKey = "apiKey"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static var instanceURL: String? {
        get { defaults?.string(forKey: instanceURLKey) }
        set { defaults?.set(newValue, forKey: instanceURLKey) }
    }

    static var apiKey: String? {
        get { defaults?.string(forKey: apiKeyKey) }
        set { defaults?.set(newValue, forKey: apiKeyKey) }
    }

    static var isConfigured: Bool {
        instanceURL != nil && apiKey != nil
    }

    static func makeAPI() -> LinkdingAPI? {
        guard let urlString = instanceURL,
              let url = URL(string: urlString),
              let key = apiKey else { return nil }
        return LinkdingAPI(baseURL: url, apiKey: key)
    }

    static func clear() {
        defaults?.removeObject(forKey: instanceURLKey)
        defaults?.removeObject(forKey: apiKeyKey)
    }
}
