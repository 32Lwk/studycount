import Foundation
import SwiftData

enum AppModelContainer {
    static func make(cloudKitEnabled: Bool) throws -> ModelContainer {
        let schema = Schema([
            StudySession.self,
            Material.self,
            Tag.self,
            StudyTask.self,
        ])

        let storeURL = try resolveStoreURL()
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: cloudKitEnabled ? .automatic : .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func resolveStoreURL() throws -> URL {
        if let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupId) {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            return base.appendingPathComponent("StudyCount.store")
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("StudyCount.store")
    }
}
