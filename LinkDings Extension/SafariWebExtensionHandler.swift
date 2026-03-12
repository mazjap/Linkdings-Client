import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let appGroupID = "group.com.mazjap.LinkDings-Client"

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        guard let type = message?["type"] as? String else {
            respond(context, with: ["error": "Missing message type"])
            return
        }

        switch type {
        case "checkSetup":
            let defaults = UserDefaults(suiteName: appGroupID)
            let configured = defaults?.string(forKey: "instanceURL") != nil
                          && defaults?.string(forKey: "apiKey") != nil
            respond(context, with: ["configured": configured])

        case "saveBookmark":
            guard
                let urlString = message?["url"] as? String,
                let defaults = UserDefaults(suiteName: appGroupID),
                let instanceURLString = defaults.string(forKey: "instanceURL"),
                let instanceURL = URL(string: instanceURLString),
                let apiKey = defaults.string(forKey: "apiKey")
            else {
                respond(context, with: ["success": false, "error": "Not configured. Open the LinkDings app to set up your instance."])
                return
            }

            Task {
                do {
                    try await saveBookmark(
                        url: urlString,
                        title: message?["title"] as? String ?? "",
                        description: message?["description"] as? String ?? "",
                        tagNames: message?["tagNames"] as? [String] ?? [],
                        instanceURL: instanceURL,
                        apiKey: apiKey
                    )
                    self.respond(context, with: ["success": true])
                } catch {
                    self.respond(context, with: ["success": false, "error": error.localizedDescription])
                }
            }

        default:
            respond(context, with: ["error": "Unknown message type: \(type)"])
        }
    }

    // MARK: - API

    private func saveBookmark(url: String, title: String, description: String,
                              tagNames: [String], instanceURL: URL, apiKey: String) async throws {
        let endpoint = instanceURL.appendingPathComponent("api/bookmarks/")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "url": url,
            "title": title,
            "description": description,
            "tag_names": tagNames,
            "is_archived": false,
            "unread": false,
            "shared": false
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "LinkDings", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned error \(code)"])
        }
    }

    // MARK: - Helper

    private func respond(_ context: NSExtensionContext, with dict: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: dict]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
