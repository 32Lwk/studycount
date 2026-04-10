import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var pro: ProPurchaseManager
    @Query(sort: \StudySession.recordDate, order: .reverse) private var sessions: [StudySession]
    @AppStorage(AppUserDefaults.dayStartMinutesKey) private var dayStartMinutes = 0
    @AppStorage(AppUserDefaults.dailyGoalMinutesKey) private var dailyGoalMinutes = 60
    @AppStorage(AppUserDefaults.weeklyGoalMinutesKey) private var weeklyGoalMinutes = 300

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    streakSection
                    goalSection
                    heatmapSection
                    dailyChartSection
                    tagChartSection
                    materialChartSection
                    if !pro.isPro {
                        AdBannerPlaceholder()
                    }
                }
                .padding()
            }
            .navigationTitle("統計")
        }
    }

    private var streakSection: some View {
        let rec = StreakService.recordingStreak(
            sessions: sessions,
            calendar: calendar,
            dayStartMinutes: dayStartMinutes
        )
        let goal = StreakService.goalStreak(
            sessions: sessions,
            calendar: calendar,
            dayStartMinutes: dayStartMinutes,
            dailyGoalMinutes: dailyGoalMinutes
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text("ストリーク")
                .font(.headline)
            HStack {
                Label("記録 \(rec) 日", systemImage: "flame")
                Spacer()
                Label("目標 \(goal) 日", systemImage: "target")
            }
            .font(.subheadline)
        }
    }

    private var goalSection: some View {
        let logicalToday = LogicalDay.logicalCalendarDay(for: Date(), calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
        let totals = StreakService.minutesByLogicalDay(sessions: sessions, calendar: calendar, dayStartMinutes: dayStartMinutes)
        let today = totals[logicalToday] ?? 0
        let week = StreakService.weeklyTotalMinutes(
            sessions: sessions,
            calendar: calendar,
            dayStartMinutes: dayStartMinutes,
            weekContaining: Date()
        )
        return VStack(alignment: .leading, spacing: 8) {
            Text("Goals (today / this week)")
                .font(.headline)
            Text("Today: \(today) / \(dailyGoalMinutes) min")
            Text("Week: \(week) / \(weeklyGoalMinutes) min")
                .foregroundStyle(.secondary)
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heatmap (12 weeks)")
                .font(.headline)
            HeatmapGridView(
                sessions: sessions,
                calendar: calendar,
                dayStartMinutes: dayStartMinutes,
                weeks: 12
            )
        }
    }

    private var dailyChartSection: some View {
        let pts = last14DailyPoints()
        return VStack(alignment: .leading, spacing: 8) {
            Text("過去14日の合計（分）")
                .font(.headline)
            Chart(pts, id: \.day) { p in
                BarMark(
                    x: .value("日", p.day, unit: .day),
                    y: .value("分", p.minutes)
                )
                .accessibilityLabel(Text(p.day.formatted(date: .abbreviated, time: .omitted)))
                .accessibilityValue(Text("\(p.minutes) 分"))
            }
            .frame(height: 180)
        }
    }

    @ViewBuilder
    private var tagChartSection: some View {
        let data = tagTotals()
        if !data.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("タグ別（分）")
                    .font(.headline)
                Chart(data, id: \.name) { row in
                    SectorMark(
                        angle: .value("分", row.minutes),
                        innerRadius: .ratio(0.45),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("タグ", row.name))
                }
                .frame(height: 200)
            }
        }
    }

    @ViewBuilder
    private var materialChartSection: some View {
        let data = materialTotals()
        if !data.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("教材別（分）")
                    .font(.headline)
                Chart(data, id: \.name) { row in
                    BarMark(
                        x: .value("分", row.minutes),
                        y: .value("教材", row.name)
                    )
                }
                .frame(height: CGFloat(max(120, data.count * 28)))
            }
        }
    }

    private func last14DailyPoints() -> [(day: Date, minutes: Int)] {
        let totals = StreakService.minutesByLogicalDay(sessions: sessions, calendar: calendar, dayStartMinutes: dayStartMinutes)
        let end = LogicalDay.logicalCalendarDay(for: Date(), calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
        return (0 ..< 14).compactMap { offset -> (Date, Int)? in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: end) else { return nil }
            return (d, totals[d] ?? 0)
        }.reversed()
    }

    private func tagTotals() -> [(name: String, minutes: Int)] {
        var map: [String: Int] = [:]
        for s in sessions {
            if s.tags.isEmpty {
                map["（タグなし）", default: 0] += s.durationMinutes
            } else {
                for t in s.tags {
                    map[t.name, default: 0] += s.durationMinutes
                }
            }
        }
        return map.map { (name: $0.key, minutes: $0.value) }.sorted { $0.minutes > $1.minutes }
    }

    private func materialTotals() -> [(name: String, minutes: Int)] {
        var map: [String: Int] = [:]
        for s in sessions {
            let key = s.material?.name ?? "（教材なし）"
            map[key, default: 0] += s.durationMinutes
        }
        return map.map { (name: $0.key, minutes: $0.value) }.sorted { $0.minutes > $1.minutes }
    }
}

private struct HeatmapGridView: View {
    let sessions: [StudySession]
    let calendar: Calendar
    let dayStartMinutes: Int
    let weeks: Int

    private var totals: [Date: Int] {
        StreakService.minutesByLogicalDay(sessions: sessions, calendar: calendar, dayStartMinutes: dayStartMinutes)
    }

    private var maxMin: Int {
        max(totals.values.max() ?? 1, 1)
    }

    var body: some View {
        let cells = buildCells()
        let columns = Array(repeating: GridItem(.flexible(minimum: 10), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                cell(for: day)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Study heatmap"))
    }

    private func cell(for day: Date) -> some View {
        let m = totals[day] ?? 0
        let intensity = Double(m) / Double(maxMin)
        return RoundedRectangle(cornerRadius: 3)
            .fill(Color.accentColor.opacity(0.15 + intensity * 0.85))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if m > 0 {
                    Text("\(m)")
                        .font(.system(size: 8))
                        .minimumScaleFactor(0.5)
                }
            }
            .accessibilityLabel(Text(day.formatted(date: .abbreviated, time: .omitted)))
            .accessibilityValue(Text("\(m) 分"))
    }

    private func buildCells() -> [Date] {
        let end = LogicalDay.logicalCalendarDay(for: Date(), calendar: calendar, dayStartMinutesFromMidnight: dayStartMinutes)
        let count = weeks * 7
        return (0 ..< count).compactMap { i in
            calendar.date(byAdding: .day, value: -(count - 1 - i), to: end)
        }
    }
}
