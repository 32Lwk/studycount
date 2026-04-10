import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var pro: ProPurchaseManager

    @AppStorage(AppUserDefaults.dayStartMinutesKey) private var dayStartMinutes = 0
    @AppStorage(AppUserDefaults.dailyGoalMinutesKey) private var dailyGoalMinutes = 60
    @AppStorage(AppUserDefaults.weeklyGoalMinutesKey) private var weeklyGoalMinutes = 300
    @AppStorage(AppUserDefaults.appearanceKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(AppUserDefaults.accentColorNameKey) private var accentRaw = AccentOption.blue.rawValue
    @AppStorage(AppUserDefaults.iCloudSyncEnabledKey) private var iCloudSync = false
    @AppStorage(AppUserDefaults.skipWeekendRemindersKey) private var skipWeekendReminders = false
    @AppStorage(AppUserDefaults.spotifyURLKey) private var spotifyURL = ""
    @AppStorage(AppUserDefaults.aiOptInKey) private var aiOptIn = false

    @State private var reminderSlots = ReminderStore.loadSlots()
    @State private var showDeleteConfirm = false
    @State private var showRestartHint = false
    @State private var tagName = ""
    @State private var showFocus = false

    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    var body: some View {
        NavigationStack {
            Form {
                Section("Day boundary & goals") {
                    Stepper("Day starts at: \(dayStartLabel)", value: $dayStartMinutes, in: 0 ... 23 * 60 + 45, step: 15)
                    Stepper("Daily goal: \(dailyGoalMinutes) min", value: $dailyGoalMinutes, in: 0 ... 24 * 60, step: 15)
                    Stepper("Weekly goal: \(weeklyGoalMinutes) min", value: $weeklyGoalMinutes, in: 0 ... 7 * 24 * 60, step: 30)
                }
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { a in
                            Text(appearanceLabel(a)).tag(a.rawValue)
                        }
                    }
                    Picker("Accent", selection: $accentRaw) {
                        ForEach(AccentOption.allCases) { a in
                            Text(a.rawValue.capitalized).tag(a.rawValue)
                        }
                    }
                }
                Section("Tags") {
                    HStack {
                        TextField("New tag", text: $tagName)
                        Button("Add") { addTag() }
                            .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    ForEach(tags) { t in
                        Text(t.name)
                    }
                    .onDelete(perform: deleteTag)
                }
                Section("Reminders (max 5)") {
                    Toggle("Skip Sat/Sun", isOn: $skipWeekendReminders)
                    ForEach(Array(reminderSlots.indices), id: \.self) { i in
                        ReminderSlotEditor(slot: $reminderSlots[i])
                    }
                    Button("Reschedule notifications") {
                        persistRemindersAndSchedule()
                    }
                }
                Section("iCloud") {
                    Toggle("Enable sync", isOn: $iCloudSync)
                        .onChange(of: iCloudSync) { _, _ in showRestartHint = true }
                    Text("Restart the app after changing. CloudKit container must exist in your developer account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Pro (one-time)") {
                    if pro.isPro {
                        Text("Pro unlocked")
                    } else {
                        Button("Restore purchases") {
                            Task { try? await pro.restore() }
                        }
                        Button("Purchase Study Pro") {
                            Task { try? await pro.purchase() }
                        }
                    }
                    Toggle("Opt in to GCP AI (Pro, future)", isOn: $aiOptIn)
                        .disabled(!pro.isPro)
                    Text("Turn on only after you agree to external AI processing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Focus & music") {
                    Button("Focus timer") { showFocus = true }
                    TextField("Spotify playlist URL (optional)", text: $spotifyURL)
                        .textInputAutocapitalization(.never)
                    Button("Open Spotify") {
                        SpotifyLink.open(from: spotifyURL.isEmpty ? nil : spotifyURL)
                    }
                    Text("Playback may be limited without Premium. Start with URL scheme only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Tracking") {
                    Button("Request tracking authorization (ads)") {
                        TrackingAuthorization.requestIfNeeded()
                    }
                }
                Section("Data") {
                    Button("Delete all local data", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
                Section("About") {
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")")
                    Text("Most data stays on device. Without iCloud sync, backups follow the device backup setting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showFocus) {
                FocusTimerView()
            }
            .alert("Delete all data?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAll() }
            } message: {
                Text("This removes sessions, materials, and tasks. It cannot be undone.")
            }
            .alert("Restart needed", isPresented: $showRestartHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Quit and relaunch the app to apply iCloud settings.")
            }
            .onDisappear {
                persistRemindersAndSchedule()
            }
        }
    }

    private func persistRemindersAndSchedule() {
        ReminderStore.saveSlots(reminderSlots)
        ReminderService.rescheduleAll(slots: reminderSlots, skipWeekends: skipWeekendReminders)
    }

    private var dayStartLabel: String {
        let h = dayStartMinutes / 60
        let m = dayStartMinutes % 60
        return String(format: "%02d:%02d", h, m)
    }

    private func appearanceLabel(_ a: AppAppearance) -> String {
        switch a {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    private func addTag() {
        let name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let next = (tags.map(\.sortOrder).max() ?? 0) + 1
        modelContext.insert(Tag(name: name, sortOrder: next))
        tagName = ""
    }

    private func deleteTag(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(tags[i])
        }
    }

    private func deleteAll() {
        try? modelContext.delete(model: StudySession.self)
        try? modelContext.delete(model: Material.self)
        try? modelContext.delete(model: Tag.self)
        try? modelContext.delete(model: StudyTask.self)
        WidgetSync.reload()
    }
}

private struct ReminderSlotEditor: View {
    @Binding var slot: ReminderSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("On", isOn: $slot.isEnabled)
            TextField("Message", text: $slot.title)
            DatePicker(
                "Time",
                selection: Binding(
                    get: {
                        Calendar.current.date(from: DateComponents(hour: slot.hour, minute: slot.minute)) ?? Date()
                    },
                    set: { d in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                        slot.hour = c.hour ?? 20
                        slot.minute = c.minute ?? 0
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            weekdayToggles
        }
        .padding(.vertical, 4)
    }

    private var weekdayToggles: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return VStack(alignment: .leading) {
            Text("Weekdays")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(1 ... 7, id: \.self) { wd in
                    let on = slot.weekdays.contains(wd)
                    Button {
                        if on { slot.weekdays.removeAll { $0 == wd } }
                        else { slot.weekdays.append(wd); slot.weekdays.sort() }
                    } label: {
                        Text(symbols[wd - 1])
                            .font(.caption2)
                            .padding(6)
                            .background(on ? Color.accentColor.opacity(0.25) : Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
