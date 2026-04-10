import XCTest
@testable import StudyCount

final class LogicalDayTests: XCTestCase {
    func testLogicalDayDefaultMidnight() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let date = cal.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 3))!
        let logical = LogicalDay.logicalCalendarDay(for: date, calendar: cal, dayStartMinutesFromMidnight: 0)
        let expected = cal.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        XCTAssertEqual(logical, expected)
    }

    func testLogicalDayFourAMBoundary() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let dayStart = 4 * 60
        let lateNight = cal.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 3))!
        let logical = LogicalDay.logicalCalendarDay(for: lateNight, calendar: cal, dayStartMinutesFromMidnight: dayStart)
        let expected = cal.date(from: DateComponents(year: 2026, month: 4, day: 9))!
        XCTAssertEqual(logical, expected)
    }

    func testRecordingStreak() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let d0 = cal.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 12))!
        let d1 = cal.date(from: DateComponents(year: 2026, month: 4, day: 9, hour: 12))!
        let sessions = [
            StudySession(recordDate: d0, durationMinutes: 30),
            StudySession(recordDate: d1, durationMinutes: 5),
        ]
        let streak = StreakService.recordingStreak(sessions: sessions, calendar: cal, dayStartMinutes: 0, through: d0)
        XCTAssertEqual(streak, 2)
    }
}
