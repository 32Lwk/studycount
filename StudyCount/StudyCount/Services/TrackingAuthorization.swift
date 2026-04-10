import AppTrackingTransparency
import UIKit

enum TrackingAuthorization {
    static func requestIfNeeded() {
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }
}
