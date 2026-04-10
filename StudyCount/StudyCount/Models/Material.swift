import Foundation
import SwiftData

@Model
final class Material {
    var name: String
    var sortOrder: Int
    var isArchived: Bool
    /// File name only; full path via ImageStorage
    var coverImageFileName: String?

    @Relationship(deleteRule: .nullify, inverse: \StudySession.material)
    var sessions: [StudySession]?

    @Relationship(deleteRule: .nullify, inverse: \StudyTask.linkedMaterial)
    var linkedTasks: [StudyTask]?

    init(name: String, sortOrder: Int = 0, isArchived: Bool = false, coverImageFileName: String? = nil) {
        self.name = name
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.coverImageFileName = coverImageFileName
    }
}
