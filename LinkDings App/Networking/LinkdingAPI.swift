import Foundation

struct LinkdingAPI {
    let baseURL: URL
    let apiKey: String

    // MARK: - JSON Decoder

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Request Building

    private func makeRequest(_ path: String, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var req = URLRequest(url: components.url!)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    // MARK: - Bookmarks

    func fetchBookmarks(query: String? = nil, limit: Int = 100, offset: Int = 0) async throws -> BookmarkListResponse {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        if let query, !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }
        let (data, response) = try await URLSession.shared.data(for: makeRequest("api/bookmarks/", queryItems: items))
        try validate(response)
        return try Self.decoder.decode(BookmarkListResponse.self, from: data)
    }

    func createBookmark(_ body: BookmarkRequest) async throws -> Bookmark {
        var req = makeRequest("api/bookmarks/")
        req.httpMethod = "POST"
        req.httpBody = try Self.encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response)
        return try Self.decoder.decode(Bookmark.self, from: data)
    }

    func updateBookmark(id: Int, _ body: BookmarkRequest) async throws -> Bookmark {
        var req = makeRequest("api/bookmarks/\(id)/")
        req.httpMethod = "PUT"
        req.httpBody = try Self.encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response)
        return try Self.decoder.decode(Bookmark.self, from: data)
    }

    func deleteBookmark(id: Int) async throws {
        var req = makeRequest("api/bookmarks/\(id)/")
        req.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: req)
        try validate(response)
    }

    // MARK: - Tags

    func fetchAllTags() async throws -> [Tag] {
        var all: [Tag] = []
        var offset = 0
        let limit = 100
        while true {
            let items = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)"),
            ]
            let (data, response) = try await URLSession.shared.data(for: makeRequest("api/tags/", queryItems: items))
            try validate(response)
            let page = try Self.decoder.decode(TagListResponse.self, from: data)
            all.append(contentsOf: page.results)
            if page.next == nil { break }
            offset += limit
        }
        return all
    }

    // MARK: - Validation

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw LinkdingError.httpError(http.statusCode)
        }
    }
}

enum LinkdingError: LocalizedError {
    case httpError(Int)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .httpError(let code): "Server returned error \(code)"
        case .notConfigured: "Linkding is not configured. Open Settings to add your instance URL and API key."
        }
    }
}
