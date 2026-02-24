import SwiftUI

struct JobEditorSheet: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var scheduleType: ScheduleType = .interval
    @State private var intervalMinutes = 30
    @State private var calendarHour = 9
    @State private var calendarMinute = 0
    @State private var selectedWeekdays: Set<Int> = []

    // Generation state
    @State private var isGenerating = false
    @State private var generatedScript: String?
    @State private var generatedName: String?
    @State private var claudeOutput = ""
    @State private var errorMessage: String?

    enum ScheduleType: String, CaseIterable {
        case interval = "Every N minutes"
        case daily = "Daily at time"
        case weekdays = "Specific days"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Schedule a new Claude")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            if let script = generatedScript, let name = generatedName {
                // Review step
                ReviewView(
                    name: name,
                    script: script,
                    schedule: buildSchedule(),
                    onConfirm: { createJob(name: name, script: script) },
                    onRegenerate: { regenerate() }
                )
            } else if isGenerating {
                // Generating step
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Claude is generating your job...")
                        .foregroundStyle(.secondary)
                    if !claudeOutput.isEmpty {
                        ScrollView {
                            Text(claudeOutput)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .frame(maxHeight: 150)
                    }
                    Spacer()
                }
                .padding()
            } else {
                // Input step
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What should this Claude do?")
                                .font(.subheadline).fontWeight(.medium)
                            TextField("e.g. Check Granola for new meetings and summarize them", text: $description, axis: .vertical)
                                .lineLimit(4...10)
                                .textFieldStyle(.roundedBorder)
                            Text("Describe in natural language. Claude will figure out the right tools, MCP config, working directory, and flags.")
                                .font(.caption).foregroundStyle(.tertiary)
                        }

                        SchedulePicker(
                            scheduleType: $scheduleType,
                            intervalMinutes: $intervalMinutes,
                            calendarHour: $calendarHour,
                            calendarMinute: $calendarMinute,
                            selectedWeekdays: $selectedWeekdays
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                }
            }

            Divider()

            HStack {
                if generatedScript != nil {
                    // handled by ReviewView buttons
                } else if isGenerating {
                    Spacer()
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Spacer()
                    Button("Generate Job") { generate() }
                        .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                }
                Spacer()
            }
            .padding()
        }
    }

    private func buildSchedule() -> JobSchedule {
        switch scheduleType {
        case .interval:
            return .interval(seconds: intervalMinutes * 60)
        case .daily:
            return .calendar(entries: [
                JobSchedule.CalendarEntry(hour: calendarHour, minute: calendarMinute)
            ])
        case .weekdays:
            let entries = selectedWeekdays.sorted().map { day in
                JobSchedule.CalendarEntry(weekday: day, hour: calendarHour, minute: calendarMinute)
            }
            return entries.isEmpty
                ? .calendar(entries: [JobSchedule.CalendarEntry(hour: calendarHour, minute: calendarMinute)])
                : .calendar(entries: entries)
        }
    }

    private func scheduleDescription() -> String {
        switch scheduleType {
        case .interval:
            return "every \(intervalMinutes) minutes"
        case .daily:
            return "daily at \(String(format: "%02d:%02d", calendarHour, calendarMinute))"
        case .weekdays:
            let dayNames = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let days = selectedWeekdays.sorted().compactMap { d in d >= 1 && d <= 7 ? dayNames[d] : nil }
            let dayStr = days.isEmpty ? "daily" : days.joined(separator: ", ")
            return "\(dayStr) at \(String(format: "%02d:%02d", calendarHour, calendarMinute))"
        }
    }

    private func generate() {
        isGenerating = true
        errorMessage = nil
        claudeOutput = ""

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let username = NSUserName()

        let metaPrompt = """
        I need you to create a scheduled Claude Code job. Output ONLY a JSON object with two fields:
        1. "name": a short lowercase hyphenated job name (e.g. "granola-check", "weekly-report")
        2. "script": the complete bash wrapper script content

        The script must follow this exact pattern:
        - Start with #!/bin/bash
        - Set LOG="$HOME/.<name>.log"
        - echo start timestamp to log
        - cd to the appropriate working directory
        - Run: \(home)/.local/bin/claude -p "<prompt>" with appropriate flags, redirecting >> "$LOG" 2>&1
        - echo finish timestamp to log

        For the claude command, determine:
        - The right --allowedTools based on what tools the task needs (e.g. Read,Bash,Grep,Write for code tasks; mcp__granola__* for Granola tasks)
        - Whether --mcp-config is needed (only if the task uses MCP tools that aren't in the project's default .mcp.json)
        - The right working directory based on the task description
        - Always include --dangerously-skip-permissions since this runs unattended

        The user's home is: \(home)
        Username: \(username)
        Schedule: \(scheduleDescription())

        Known MCP configs on this system:
        - Granola: \(home)/Documents/Github/every-consulting/plugins/claudie/.mcp.json (has mcp__granola__* tools)
        - Global: ~/.claude/.mcp.json (if it exists)

        User's request: \(description)

        Respond with ONLY the JSON object, no markdown fences, no explanation.
        """

        let settings = AppSettings.shared
        let process = Process()
        process.executableURL = URL(fileURLWithPath: settings.claudeBinaryPath)
        process.arguments = ["-p", metaPrompt, "--output-format", "text"]

        // Clear CLAUDECODE so claude doesn't refuse to run inside another session
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "CLAUDECODE")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                claudeOutput += text
            }
        }

        process.terminationHandler = { proc in
            Task { @MainActor in
                isGenerating = false
                if proc.terminationStatus == 0 {
                    parseGeneratedOutput(claudeOutput)
                } else {
                    errorMessage = "Claude exited with code \(proc.terminationStatus). Try again."
                }
            }
        }

        do {
            try process.run()
        } catch {
            isGenerating = false
            errorMessage = "Failed to launch claude: \(error.localizedDescription)"
        }
    }

    private func regenerate() {
        generatedScript = nil
        generatedName = nil
        claudeOutput = ""
        generate()
    }

    private func parseGeneratedOutput(_ output: String) {
        // Try to extract JSON from the output
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown fences if present
        var jsonStr = trimmed
        if jsonStr.hasPrefix("```") {
            let lines = jsonStr.split(separator: "\n", omittingEmptySubsequences: false)
            let inner = lines.dropFirst().prefix(while: { !$0.starts(with: "```") })
            jsonStr = inner.joined(separator: "\n")
        }

        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let script = json["script"] as? String else {
            errorMessage = "Failed to parse Claude's response. Try again."
            return
        }

        generatedName = name
        generatedScript = script
    }

    private func createJob(name: String, script: String) {
        let settings = AppSettings.shared
        let username = NSUserName()
        let scriptPath = "\(settings.scriptsDirectory)/\(name).sh"
        let plistPath = "\(settings.launchAgentsDirectory)/com.\(username).\(name).plist"

        // Create scripts directory
        try? FileManager.default.createDirectory(atPath: settings.scriptsDirectory, withIntermediateDirectories: true)

        // Write script
        guard FileManager.default.createFile(atPath: scriptPath, contents: script.data(using: .utf8)) else {
            errorMessage = "Failed to write script."
            return
        }
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)

        // Write plist
        let schedule = buildSchedule()
        let plistContent = generatePlist(label: "com.\(username).\(name)", scriptPath: scriptPath, schedule: schedule)
        guard FileManager.default.createFile(atPath: plistPath, contents: plistContent.data(using: .utf8)) else {
            errorMessage = "Failed to write plist."
            return
        }

        // Load
        if !LaunchdManager.load(plistPath: plistPath) {
            errorMessage = "Files created but failed to load into launchd."
            return
        }

        onSave()
        dismiss()
    }

    private func generatePlist(label: String, scriptPath: String, schedule: JobSchedule) -> String {
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

    private func calendarEntryXML(_ entry: JobSchedule.CalendarEntry, indent: String = "        ") -> String {
        var xml = ""
        if let month = entry.month { xml += "\(indent)<key>Month</key>\n\(indent)<integer>\(month)</integer>\n" }
        if let day = entry.day { xml += "\(indent)<key>Day</key>\n\(indent)<integer>\(day)</integer>\n" }
        if let weekday = entry.weekday { xml += "\(indent)<key>Weekday</key>\n\(indent)<integer>\(weekday)</integer>\n" }
        if let hour = entry.hour { xml += "\(indent)<key>Hour</key>\n\(indent)<integer>\(hour)</integer>\n" }
        if let minute = entry.minute { xml += "\(indent)<key>Minute</key>\n\(indent)<integer>\(minute)</integer>\n" }
        return xml
    }
}

/// Review the generated script before creating the job
struct ReviewView: View {
    let name: String
    let script: String
    let schedule: JobSchedule
    let onConfirm: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(name, systemImage: "terminal")
                    .font(.headline)
                Spacer()
                Text(schedule.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.primary.opacity(0.06), in: Capsule())
            }

            Text("Review the generated script:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(script)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))

            HStack {
                Button("Regenerate") { onRegenerate() }
                Spacer()
                Button("Create & Load") { onConfirm() }
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding()
    }
}
