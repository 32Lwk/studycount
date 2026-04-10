import SwiftData
import SwiftUI

@main
struct StudyCountApp: App {
    private let container: ModelContainer

    init() {
        let ck = UserDefaults.standard.bool(forKey: AppUserDefaults.iCloudSyncEnabledKey)
        do {
            container = try AppModelContainer.make(cloudKitEnabled: ck)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
