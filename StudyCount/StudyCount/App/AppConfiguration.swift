import Foundation

enum AppConstants {
    static let appGroupId = "group.dev.studycount.shared"
    static let iCloudContainerId = "iCloud.dev.studycount.StudyCount"
    static let proProductId = "dev.studycount.pro"
}

enum AppUserDefaults {
    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let dayStartMinutesKey = "dayStartMinutesFromMidnight"
    static let dailyGoalMinutesKey = "dailyGoalMinutes"
    static let weeklyGoalMinutesKey = "weeklyGoalMinutes"
    static let appearanceKey = "appearance" // system, light, dark
    static let accentColorNameKey = "accentColorName"
    static let remindersJSONKey = "remindersJSON"
    static let skipWeekendRemindersKey = "skipWeekendReminders"
    static let aiOptInKey = "aiOptIn"
    static let spotifyURLKey = "spotifyPlaylistURL"
}
