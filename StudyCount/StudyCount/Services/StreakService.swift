import Foundation

enum StreakService {
    /// 記録ストリーク: 論理日ごとに合計が 1 分以上が続く日数
    static func recordingStreak(
        sessions: [StudySession],
        calendar: Calendar,
        dayStartMinutes: Int,
        through: Date = Date()
    ) -> Int {
        let totals = minutesByLogicalDay(sessions: sessions, calendar: calendar, dayStartMinutes: dayStartMinutes)
        var count = 0
        var day = LogicalDay.logicalCalendarDay(for: through, calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
        while true {
            let m = totals[day] ?? 0
            if m >= 1 {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        return count
    }

    /// Goal-achievement streak: consecutive logical days meeting the daily minute goal.
    static func goalStreak(
        sessions: [StudySession],
        calendar: Calendar,
        dayStartMinutes: Int,
        dailyGoalMinutes: Int,
        through: Date = Date()
    ) -> Int {
        guard dailyGoalMinutes > 0 else { return 0 }
        let totals = minutesByLogicalDay(sessions: sessions, calendar: calendar, dayStartMinutes: dayStartMinutes)
        var count = 0
        var day = LogicalDay.logicalCalendarDay(for: through, calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
        while true {
            let m = totals[day] ?? 0
            if m >= dailyGoalMinutes {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        return count
    }

    static func minutesByLogicalDay(
        sessions: [StudySession],
        calendar: Calendar,
        dayStartMinutes: Int
    ) -> [Date: Int] {
        var map: [Date: Int] = [:]
        for s in sessions {
            let d = LogicalDay.logicalCalendarDay(
                for: s.recordDate,
                calendar: calendar,
                dayStartMinutesFromMidnight: dayStartMinutes
            )
            map[d, default: 0] += max(0, s.durationMinutes)
        }
        return map
    }

    static func weeklyTotalMinutes(
        sessions: [StudySession],
        calendar: Calendar,
        dayStartMinutes: Int,
        weekContaining: Date
    ) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: weekContaining) else { return 0 }
        return sessions.reduce(0) { partial, s in
            let d = LogicalDay.logicalCalendarDay(for: s.recordDate, calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
            if d >= interval.start && d < interval.end {
                return partial + max(0, s.durationMinutes)
            }
            return partial
        }
    }
}
