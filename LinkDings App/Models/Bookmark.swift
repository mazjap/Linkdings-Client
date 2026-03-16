import Foundation
import SwiftData

struct Bookmark: Codable, Identifiable {
    let id: Int
    let url: URL
    let title: String
    let description: String
    let notes: String
    let websiteTitle: String?
    let websiteDescription: String?
    let isArchived: Bool
    let unread: Bool
    let shared: Bool
    let tagNames: [String]
    let dateAdded: Date
    let dateModified: Date

    var displayTitle: String {
        title.isEmpty ? (websiteTitle ?? url.absoluteString) : title
    }

    enum CodingKeys: String, CodingKey {
        case id, url, title, description, notes
        case websiteTitle = "website_title"
        case websiteDescription = "website_description"
        case isArchived = "is_archived"
        case unread, shared
        case tagNames = "tag_names"
        case dateAdded = "date_added"
        case dateModified = "date_modified"
    }
    
    var bookmarkId: Int { id }
    
    func toRequest() -> BookmarkRequest {
        BookmarkRequest(
            url: url, title: title, description: description,
            notes: notes, isArchived: isArchived, unread: unread,
            shared: shared, tagNames: tagNames
        )
    }
}

struct BookmarkListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Bookmark]
}

struct BookmarkRequest: Codable {
    var url: URL
    var title: String
    var description: String
    var notes: String
    var isArchived: Bool
    var unread: Bool
    var shared: Bool
    var tagNames: [String]

    enum CodingKeys: String, CodingKey {
        case url, title, description, notes
        case isArchived = "is_archived"
        case unread, shared
        case tagNames = "tag_names"
    }

    init(url: URL, title: String = "", description: String = "", notes: String = "",
         isArchived: Bool = false, unread: Bool = false, shared: Bool = false, tagNames: [String] = []) {
        self.url = url
        self.title = title
        self.description = description
        self.notes = notes
        self.isArchived = isArchived
        self.unread = unread
        self.shared = shared
        self.tagNames = tagNames
    }
}

struct BookmarkPatchRequest: Codable {
    var url: URL?
    var title: String?
    var description: String?
    var notes: String?
    var websiteTitle: String?
    var websiteDescription: String?
    var isArchived: Bool?
    var unread: Bool?
    var shared: Bool?
    var tagNames: [String]?
    
    init(url: URL? = nil, title: String? = nil, description: String? = nil, notes: String? = nil, websiteTitle: String? = nil, websiteDescription: String? = nil, isArchived: Bool? = nil, unread: Bool? = nil, shared: Bool? = nil, tagNames: [String]? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.notes = notes
        self.websiteTitle = websiteTitle
        self.websiteDescription = websiteDescription
        self.isArchived = isArchived
        self.unread = unread
        self.shared = shared
        self.tagNames = tagNames
    }
    
    enum CodingKeys: String, CodingKey {
        case url, title, description, notes
        case websiteTitle = "website_title"
        case websiteDescription = "website_description"
        case isArchived = "is_archived"
        case unread, shared
        case tagNames = "tag_names"
    }
}
