import Foundation
import SwiftData

@Model
final class StudySession {
    /// When the study happened (user-editable)
    var recordDate: Date
    var durationMinutes: Int
    var memo: String
    var createdAt: Date

    var material: Material?

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]

    @Relationship(deleteRule: .nullify, inverse: \StudyTask.linkedSession)
    var linkedTasks: [StudyTask]?

    init(
        recordDate: Date = Date(),
        durationMinutes: Int,
        memo: String = "",
        createdAt: Date = Date(),
        material: Material? = nil,
        tags: [Tag] = []
    ) {
        self.recordDate = recordDate
        self.durationMinutes = durationMinutes
        self.memo = memo
        self.createdAt = createdAt
        self.material = material
        self.tags = tags
    }
}
