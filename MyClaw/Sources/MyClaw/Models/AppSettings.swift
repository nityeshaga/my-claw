import Foundation

/// User preferences for the app
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var claudeBinaryPath: String {
        didSet { UserDefaults.standard.set(claudeBinaryPath, forKey: "claudeBinaryPath") }
    }
    @Published var indexFilePath: String {
        didSet { UserDefaults.standard.set(indexFilePath, forKey: "indexFilePath") }
    }
    @Published var scriptsDirectory: String {
        didSet { UserDefaults.standard.set(scriptsDirectory, forKey: "scriptsDirectory") }
    }
    @Published var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: "showNotifications") }
    }
    @Published var notifyOnFailureOnly: Bool {
        didSet { UserDefaults.standard.set(notifyOnFailureOnly, forKey: "notifyOnFailureOnly") }
    }

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.claudeBinaryPath = UserDefaults.standard.string(forKey: "claudeBinaryPath")
            ?? "\(home)/.local/bin/claude"
        self.indexFilePath = UserDefaults.standard.string(forKey: "indexFilePath")
            ?? "\(home)/.claude/job-monitor/jobs-index.jsonl"
        self.scriptsDirectory = UserDefaults.standard.string(forKey: "scriptsDirectory")
            ?? "\(home)/.claude/scripts"
        self.showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true
        self.notifyOnFailureOnly = UserDefaults.standard.object(forKey: "notifyOnFailureOnly") as? Bool ?? false
    }

    var launchAgentsDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents"
    }
}
