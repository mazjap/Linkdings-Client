import Foundation
import SwiftData

// MARK: - API DTO

struct Bookmark: Codable, Identifiable {
    let id: Int
    let url: String
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
        title.isEmpty ? (websiteTitle ?? url) : title
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
}

struct BookmarkListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Bookmark]
}

struct BookmarkRequest: Codable {
    var url: String
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

    init(url: String, title: String = "", description: String = "", notes: String = "",
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

// MARK: - SwiftData Cache

@Model
class CachedBookmark {
    @Attribute(.unique) var id: Int
    var url: String
    var title: String
    var bookmarkDescription: String
    var notes: String
    var websiteTitle: String?
    var isArchived: Bool
    var unread: Bool
    var shared: Bool
    var tagNames: [String]
    var dateAdded: Date
    var dateModified: Date

    var displayTitle: String {
        title.isEmpty ? (websiteTitle ?? url) : title
    }

    init(from bookmark: Bookmark) {
        self.id = bookmark.id
        self.url = bookmark.url
        self.title = bookmark.title
        self.bookmarkDescription = bookmark.description
        self.notes = bookmark.notes
        self.websiteTitle = bookmark.websiteTitle
        self.isArchived = bookmark.isArchived
        self.unread = bookmark.unread
        self.shared = bookmark.shared
        self.tagNames = bookmark.tagNames
        self.dateAdded = bookmark.dateAdded
        self.dateModified = bookmark.dateModified
    }

    func update(from bookmark: Bookmark) {
        url = bookmark.url
        title = bookmark.title
        bookmarkDescription = bookmark.description
        notes = bookmark.notes
        websiteTitle = bookmark.websiteTitle
        isArchived = bookmark.isArchived
        unread = bookmark.unread
        shared = bookmark.shared
        tagNames = bookmark.tagNames
        dateAdded = bookmark.dateAdded
        dateModified = bookmark.dateModified
    }

    func toRequest() -> BookmarkRequest {
        BookmarkRequest(
            url: url, title: title, description: bookmarkDescription,
            notes: notes, isArchived: isArchived, unread: unread,
            shared: shared, tagNames: tagNames
        )
    }
}
