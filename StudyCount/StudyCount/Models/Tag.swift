import Foundation
import SwiftData

@Model
final class Tag {
    var name: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \StudySession.tags)
    var sessions: [StudySession]?

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
