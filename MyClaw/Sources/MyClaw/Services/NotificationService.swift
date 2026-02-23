import Foundation
import AppKit

/// Sends macOS notifications for job completion/failure via NSUserNotification (bundle-safe)
enum NotificationService {
    static func setup() {
        // No-op: notifications are sent on-demand and don't require bundle registration
    }

    static func notifySessionComplete(session: SessionRun) {
        let settings = AppSettings.shared
        guard settings.showNotifications else { return }
        if settings.notifyOnFailureOnly && session.isSuccess { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        let title = session.isSuccess ? "Session Complete" : "Session Failed"
        var body = "\(session.projectName) — \(session.shortSessionId)"
        if let tokens = session.totalInputTokens {
            body += " (\(DateFormatting.tokenString(tokens)) tokens)"
        }
        process.arguments = ["-e", "display notification \"\(body)\" with title \"\(title)\""]
        try? process.run()
    }
}
