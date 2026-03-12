import Foundation
import SwiftData

// MARK: - API DTO

struct Tag: Codable, Identifiable {
    let id: Int
    let name: String
    let dateAdded: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case dateAdded = "date_added"
    }
}

struct TagListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Tag]
}

// MARK: - SwiftData Cache

@Model
class CachedTag {
    @Attribute(.unique) var id: Int
    var name: String
    var dateAdded: Date

    init(from tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.dateAdded = tag.dateAdded
    }
}
