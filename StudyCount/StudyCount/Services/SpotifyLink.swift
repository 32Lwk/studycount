import UIKit

enum SpotifyLink {
    /// Opens a user-provided playlist URL, or falls back to the Spotify app / web.
    static func open(from urlString: String?) {
        let trimmed = urlString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let u = URL(string: trimmed), !trimmed.isEmpty {
            UIApplication.shared.open(u)
            return
        }
        if let u = URL(string: "spotify://") {
            UIApplication.shared.open(u)
        }
    }
}
