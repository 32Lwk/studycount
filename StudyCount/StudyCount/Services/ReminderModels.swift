import Foundation

/// Up to 5 reminder schedules; each may repeat on multiple weekdays at one time.
struct ReminderSlot: Codable, Identifiable, Equatable {
    var id: UUID
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    /// `Calendar.Component.weekday` (1 = Sunday ... 7 = Saturday)
    var weekdays: [Int]
    var title: String

    init(
        id: UUID = UUID(),
        isEnabled: Bool = false,
        hour: Int = 20,
        minute: Int = 0,
        weekdays: [Int] = [2, 3, 4, 5, 6],
        title: String = "勉強の時間です"
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.title = title
    }
}

enum ReminderStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func loadSlots() -> [ReminderSlot] {
        guard let data = UserDefaults.standard.data(forKey: AppUserDefaults.remindersJSONKey),
              let slots = try? decoder.decode([ReminderSlot].self, from: data)
        else {
            return (0 ..< 5).map { _ in ReminderSlot() }
        }
        var arr = slots
        while arr.count < 5 { arr.append(ReminderSlot()) }
        if arr.count > 5 { arr = Array(arr.prefix(5)) }
        return arr
    }

    static func saveSlots(_ slots: [ReminderSlot]) {
        let trimmed = Array(slots.prefix(5))
        if let data = try? encoder.encode(trimmed) {
            UserDefaults.standard.set(data, forKey: AppUserDefaults.remindersJSONKey)
        }
    }
}
