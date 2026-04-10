import SwiftUI

/// Replace this view with a real ad SDK wrapper before release; align Info.plist and ATT.
struct AdBannerPlaceholder: View {
    var body: some View {
        Text("Ad banner placeholder (integrate AdMob or similar for production)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
    }
}
