import SwiftUI

struct MainTabView: View {
    @StateObject private var pro = ProPurchaseManager()
    @AppStorage(AppUserDefaults.appearanceKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(AppUserDefaults.accentColorNameKey) private var accentRaw = AccentOption.blue.rawValue

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    private var accent: AccentOption {
        AccentOption(rawValue: accentRaw) ?? .blue
    }

    var body: some View {
        TabView {
            SessionListView()
                .tabItem { Label("記録", systemImage: "clock") }
            MaterialListView()
                .tabItem { Label("教材", systemImage: "book") }
            StatsView()
                .tabItem { Label("統計", systemImage: "chart.bar") }
            TaskListView()
                .tabItem { Label("タスク", systemImage: "checklist") }
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
        .environmentObject(pro)
        .tint(accent.color)
        .preferredColorScheme(appearance.colorScheme)
    }
}
