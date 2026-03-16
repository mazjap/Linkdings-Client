import Foundation
import SwiftData

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
