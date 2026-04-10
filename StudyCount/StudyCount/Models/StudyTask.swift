import Foundation
import SwiftData

/// Task with optional links to a session or material.
@Model
final class StudyTask {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    /// 0 = low, 1 = mid, 2 = high
    var priority: Int
    var sortOrder: Int

    var linkedSession: StudySession?
    var linkedMaterial: Material?

    init(
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        priority: Int = 1,
        sortOrder: Int = 0
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.priority = priority
        self.sortOrder = sortOrder
    }
}
