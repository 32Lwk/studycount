import Foundation
import UserNotifications

enum ReminderService {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func rescheduleAll(slots: [ReminderSlot], skipWeekends: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let filteredSlots = Array(slots.prefix(5))
        for slot in filteredSlots where slot.isEnabled {
            for weekday in slot.weekdays {
                if skipWeekends, [1, 7].contains(weekday) { continue }
                var components = DateComponents()
                components.weekday = weekday
                components.hour = slot.hour
                components.minute = slot.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = slot.title
                content.sound = .default
                let id = "studycount.reminder.\(slot.id.uuidString).weekday.\(weekday)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}
