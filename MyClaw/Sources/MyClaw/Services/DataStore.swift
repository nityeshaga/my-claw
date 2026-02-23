import Foundation
import SwiftUI
import Combine

/// Central data store: discovers jobs, sessions, and monitors for updates
@MainActor
class DataStore: ObservableObject {
    @Published var sessions: [SessionRun] = []
    @Published var jobs: [Job] = []
    @Published var isLoading = true

    private let settings = AppSettings.shared
    private var fileMonitor: FileMonitor?
    private var lastIndexOffset: UInt64 = 0

    init() {}

    /// Initial data load
    func load() {
        isLoading = true
        sessions = loadSessions()
        jobs = discoverJobs()
        isLoading = false
        startMonitoring()
    }

    /// Reload all data
    func refresh() {
        sessions = loadSessions()
        jobs = discoverJobs()
    }

    // MARK: - Sessions

    private func loadSessions() -> [SessionRun] {
        let entries = JSONLParser.parse(SessionRun.self, from: settings.indexFilePath)
        // Most recent first
        return entries.sorted { ($0.finishedDate ?? .distantPast) > ($1.finishedDate ?? .distantPast) }
    }

    // MARK: - Jobs

    private func discoverJobs() -> [Job] {
        let launchAgentsDir = settings.launchAgentsDirectory
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(atPath: launchAgentsDir) else { return [] }

        let plistFiles = files.filter { $0.hasPrefix("com.") && $0.hasSuffix(".plist") }

        return plistFiles.compactMap { filename -> Job? in
            let plistPath = "\(launchAgentsDir)/\(filename)"
            guard let plistData = PlistParser.parse(at: plistPath) else { return nil }

            // Parse wrapper script for prompt/cwd/tools
            let scriptData = ScriptParser.parse(at: plistData.scriptPath)

            // Check launchctl status
            let (isLoaded, exitCode, pid) = checkLaunchdStatus(label: plistData.label)

            return Job(
                label: plistData.label,
                scriptPath: plistData.scriptPath,
                plistPath: plistPath,
                schedule: plistData.schedule,
                prompt: scriptData?.prompt,
                workingDirectory: scriptData?.workingDirectory,
                allowedTools: scriptData?.allowedTools,
                mcpConfig: scriptData?.mcpConfig,
                isLoaded: isLoaded,
                lastExitCode: exitCode,
                pid: pid
            )
        }
    }

    private func checkLaunchdStatus(label: String) -> (isLoaded: Bool, exitCode: Int?, pid: Int?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", label]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (false, nil, nil)
        }

        guard process.terminationStatus == 0 else { return (false, nil, nil) }

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Output format: "{" key = value; ... "}" or tab-separated PID ExitCode Label
        // launchctl list <label> gives structured output with "pid" and "exit code" lines
        var exitCode: Int?
        var pid: Int?

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            if trimmed.contains("exit code") || trimmed.contains("LastExitStatus") {
                if let num = trimmed.split(separator: "=").last?.trimmingCharacters(in: .whitespaces .union(.punctuationCharacters)),
                   let code = Int(num) {
                    exitCode = code
                }
            }
            if trimmed.hasPrefix("pid") || trimmed.contains("PID") {
                if let num = trimmed.split(separator: "=").last?.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters)),
                   let p = Int(num) {
                    pid = p
                }
            }
        }

        return (true, exitCode, pid)
    }

    // MARK: - File Monitoring

    private func startMonitoring() {
        // Get initial file size as offset
        if let attrs = try? FileManager.default.attributesOfItem(atPath: settings.indexFilePath),
           let size = attrs[.size] as? UInt64 {
            lastIndexOffset = size
        }

        fileMonitor = FileMonitor(path: settings.indexFilePath) { [weak self] in
            Task { @MainActor in
                self?.handleIndexUpdate()
            }
        }
        fileMonitor?.start()
    }

    private func handleIndexUpdate() {
        let (newEntries, newOffset) = JSONLParser.parseTail(
            SessionRun.self, from: settings.indexFilePath, offset: lastIndexOffset
        )
        lastIndexOffset = newOffset

        if !newEntries.isEmpty {
            sessions.insert(contentsOf: newEntries, at: 0)
            // Refresh job status too
            jobs = discoverJobs()
        }
    }

    // MARK: - Computed properties

    var sessionsToday: [SessionRun] {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let date = session.finishedDate else { return false }
            return calendar.isDateInToday(date)
        }
    }

    var totalTokensToday: Int {
        sessionsToday.reduce(0) { $0 + $1.totalTokens }
    }

    var successRateToday: Double {
        let today = sessionsToday
        guard !today.isEmpty else { return 1.0 }
        let successes = today.filter(\.isSuccess).count
        return Double(successes) / Double(today.count)
    }

    /// Find sessions that likely belong to a specific job (matching CWD)
    func sessions(for job: Job) -> [SessionRun] {
        guard let jobCwd = job.workingDirectory else { return [] }
        return sessions.filter { $0.cwd == jobCwd }
    }
}
