import Foundation

/// Logical calendar day using the user-defined day-start offset from midnight.
enum LogicalDay {
    /// `dayStartMinutesFromMidnight`: 0...1439（デフォルト 0 = 0:00）
    static func logicalCalendarDay(for date: Date, calendar: Calendar = .current, dayStartMinutesFromMidnight: Int) -> Date {
        var cal = calendar
        cal.timeZone = calendar.timeZone
        let start = clampDayStart(dayStartMinutesFromMidnight)
        let h = start / 60
        let m = start % 60
        guard let shifted = cal.date(byAdding: .minute, value: -(h * 60 + m), to: date) else {
            return cal.startOfDay(for: date)
        }
        return cal.startOfDay(for: shifted)
    }

    static func clampDayStart(_ minutes: Int) -> Int {
        min(max(minutes, 0), 23 * 60 + 59)
    }
}
