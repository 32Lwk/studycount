import SwiftData
import SwiftUI
import WidgetKit

struct StudyCountWidget: Widget {
    let kind: String = "StudyCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StudyCountWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's study")
        .description("Total minutes recorded for the current logical day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), minutes: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), minutes: fetchMinutes()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), minutes: fetchMinutes())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func fetchMinutes() -> Int {
        let ck = UserDefaults.standard.bool(forKey: AppUserDefaults.iCloudSyncEnabledKey)
        guard let container = try? AppModelContainer.make(cloudKitEnabled: ck) else { return 0 }
        let ctx = ModelContext(container)
        let dayStart = UserDefaults.standard.integer(forKey: AppUserDefaults.dayStartMinutesKey)
        let desc = FetchDescriptor<StudySession>()
        guard let sessions = try? ctx.fetch(desc) else { return 0 }
        let cal = Calendar.current
        let logicalToday = LogicalDay.logicalCalendarDay(for: Date(), calendar: cal, dayStartMinutesFromMidnight: dayStart)
        return sessions.reduce(0) { sum, s in
            let d = LogicalDay.logicalCalendarDay(for: s.recordDate, calendar: cal, dayStartMinutesFromMidnight: dayStart)
            return d == logicalToday ? sum + max(0, s.durationMinutes) : sum
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let minutes: Int
}

struct StudyCountWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(entry.minutes) min")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

@main
struct StudyCountWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyCountWidget()
    }
}
