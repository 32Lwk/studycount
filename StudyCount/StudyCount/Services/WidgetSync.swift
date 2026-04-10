import Foundation
import WidgetKit

enum WidgetSync {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
