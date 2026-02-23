import Foundation

/// Manages launchd jobs: load, unload, create, delete
enum LaunchdManager {
    private static let settings = AppSettings.shared

    /// Load a plist into launchd
    static func load(plistPath: String) -> Bool {
        runLaunchctl(["load", plistPath])
    }

    /// Unload a plist from launchd
    static func unload(plistPath: String) -> Bool {
        runLaunchctl(["unload", plistPath])
    }

    /// Trigger an immediate run of a loaded job
    static func start(label: String) -> Bool {
        runLaunchctl(["start", label])
    }

    /// Create a new scheduled job (wrapper script + plist)
    static func createJob(
        name: String,
        prompt: String,
        workingDirectory: String,
        schedule: JobSchedule,
        allowedTools: [String]? = nil,
        mcpConfig: String? = nil
    ) -> (scriptPath: String, plistPath: String)? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let username = NSUserName()
        let scriptPath = "\(settings.scriptsDirectory)/\(name).sh"
        let plistPath = "\(settings.launchAgentsDirectory)/com.\(username).\(name).plist"

        // Create scripts directory
        try? FileManager.default.createDirectory(atPath: settings.scriptsDirectory, withIntermediateDirectories: true)

        // Write wrapper script
        var script = """
        #!/bin/bash
        # Claude Job: \(name)
        # Created: \(ISO8601DateFormatter().string(from: .now))

        LOG="$HOME/.\(name).log"

        echo "=== Started at $(date) ===" >> "$LOG"
        cd \(workingDirectory)

        \(home)/.local/bin/claude -p "\(prompt.replacingOccurrences(of: "\"", with: "\\\""))"
        """

        if let tools = allowedTools, !tools.isEmpty {
            script += " \\\n  --allowedTools \"\(tools.joined(separator: ","))\""
        }
        if let mcp = mcpConfig {
            script += " \\\n  --mcp-config \(mcp)"
        }
        script += " \\\n  --dangerously-skip-permissions >> \"$LOG\" 2>&1\n"
        script += "\necho \"=== Finished at $(date) ===\" >> \"$LOG\"\n"

        guard FileManager.default.createFile(atPath: scriptPath, contents: script.data(using: .utf8)) else {
            return nil
        }

        // Make executable
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)

        // Write plist
        let plistContent = generatePlist(label: "com.\(username).\(name)", scriptPath: scriptPath, schedule: schedule)
        guard FileManager.default.createFile(atPath: plistPath, contents: plistContent.data(using: .utf8)) else {
            return nil
        }

        return (scriptPath, plistPath)
    }

    /// Delete a job (unload + remove files)
    static func deleteJob(job: Job) -> Bool {
        _ = unload(plistPath: job.plistPath)
        try? FileManager.default.removeItem(atPath: job.plistPath)
        try? FileManager.default.removeItem(atPath: job.scriptPath)
        return true
    }

    // MARK: - Private

    private static func runLaunchctl(_ args: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func generatePlist(label: String, scriptPath: String, schedule: JobSchedule) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>

            <key>ProgramArguments</key>
            <array>
                <string>\(scriptPath)</string>
            </array>

        """

        switch schedule {
        case .interval(let seconds):
            xml += """
                <key>StartInterval</key>
                <integer>\(seconds)</integer>

            """
        case .calendar(let entries):
            if entries.count == 1, let entry = entries.first {
                xml += "    <key>StartCalendarInterval</key>\n    <dict>\n"
                xml += calendarEntryXML(entry)
                xml += "    </dict>\n\n"
            } else {
                xml += "    <key>StartCalendarInterval</key>\n    <array>\n"
                for entry in entries {
                    xml += "        <dict>\n"
                    xml += calendarEntryXML(entry, indent: "            ")
                    xml += "        </dict>\n"
                }
                xml += "    </array>\n\n"
            }
        case .unknown:
            break
        }

        xml += """
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        return xml
    }

    private static func calendarEntryXML(_ entry: JobSchedule.CalendarEntry, indent: String = "        ") -> String {
        var xml = ""
        if let month = entry.month {
            xml += "\(indent)<key>Month</key>\n\(indent)<integer>\(month)</integer>\n"
        }
        if let day = entry.day {
            xml += "\(indent)<key>Day</key>\n\(indent)<integer>\(day)</integer>\n"
        }
        if let weekday = entry.weekday {
            xml += "\(indent)<key>Weekday</key>\n\(indent)<integer>\(weekday)</integer>\n"
        }
        if let hour = entry.hour {
            xml += "\(indent)<key>Hour</key>\n\(indent)<integer>\(hour)</integer>\n"
        }
        if let minute = entry.minute {
            xml += "\(indent)<key>Minute</key>\n\(indent)<integer>\(minute)</integer>\n"
        }
        return xml
    }
}
