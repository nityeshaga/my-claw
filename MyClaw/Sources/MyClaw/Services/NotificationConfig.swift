import Foundation

/// Writes Slack notification settings to a JSON file on disk so the hook script can read them.
enum NotificationConfig {
    private static let configPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/job-monitor/notification-config.json"
    }()

    /// Write current notification settings to disk. Safe to call frequently.
    static func write() {
        let settings = AppSettings.shared
        let config: [String: Any] = [
            "notify_slack": settings.notifySlack,
            "slack_webhook_url": settings.slackWebhookURL,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }

        let dir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: configPath, contents: data)
    }
}
