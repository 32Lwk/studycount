import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @AppStorage(AppUserDefaults.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false
    @AppStorage(AppUserDefaults.iCloudSyncEnabledKey) private var iCloudSync = false
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            VStack(spacing: 16) {
                Text("StudyCount")
                    .font(.largeTitle.bold())
                Text("Track study time, materials, and tags. Works offline.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Next") { page = 1 }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .tag(0)

            VStack(spacing: 16) {
                Text("Notifications")
                    .font(.title2.bold())
                Text("Used for study reminders. You can change this later in Settings.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Allow notifications") {
                    Task {
                        _ = await ReminderService.requestAuthorization()
                        page = 2
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Skip") { page = 2 }
                Spacer()
            }
            .padding()
            .tag(1)

            VStack(spacing: 16) {
                Text("iCloud (optional)")
                    .font(.title2.bold())
                Text("ISBN lookups use openBD as explained on the material screen. Enabling iCloud syncs your data to your account. You can leave this off at first.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Toggle("Enable iCloud sync (restart required)", isOn: $iCloudSync)
                    .padding(.horizontal)
                Button("Get started") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
