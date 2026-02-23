import Foundation
import UserNotifications

/// Sends macOS notifications for job completion/failure
enum NotificationService {
    static func setup() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func notifySessionComplete(session: SessionRun) {
        let settings = AppSettings.shared
        guard settings.showNotifications else { return }
        if settings.notifyOnFailureOnly && session.isSuccess { return }

        let content = UNMutableNotificationContent()
        content.title = session.isSuccess ? "Session Complete" : "Session Failed"
        content.body = "\(session.projectName) — \(session.shortSessionId)"
        if let tokens = session.totalInputTokens {
            content.body += " (\(DateFormatting.tokenString(tokens)) tokens)"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: session.sessionId,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
