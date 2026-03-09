import Foundation

/// Writes Slack notification settings to a JSON file on disk so the hook script can read them.
enum NotificationConfig {
    private static let configPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/job-monitor/notification-config.json"
    }()

    /// Write current notification settings to disk. Safe to call frequently.
    /// When called without arguments, reads from AppSettings.shared.
    /// Pass explicit values during AppSettings.init() to avoid re-entrant access.
    static func write(notifySlack: Bool? = nil, slackWebhookURL: String? = nil) {
        let slack: Bool
        let webhook: String
        if let n = notifySlack, let w = slackWebhookURL {
            slack = n
            webhook = w
        } else {
            let settings = AppSettings.shared
            slack = notifySlack ?? settings.notifySlack
            webhook = slackWebhookURL ?? settings.slackWebhookURL
        }

        let config: [String: Any] = [
            "notify_slack": slack,
            "slack_webhook_url": webhook,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }

        let dir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: configPath, contents: data)
    }
}
