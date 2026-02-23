import Foundation

/// A discovered scheduled job, assembled from plist + wrapper script
struct Job: Identifiable, Hashable {
    let label: String
    let scriptPath: String
    let plistPath: String
    let schedule: JobSchedule
    var prompt: String?
    var workingDirectory: String?
    var allowedTools: [String]?
    var mcpConfig: String?
    var isLoaded: Bool = false
    var lastExitCode: Int?
    var pid: Int?

    var id: String { label }

    var name: String {
        // com.nityesh.granola-check → granola-check
        let parts = label.split(separator: ".")
        if parts.count >= 3 {
            return parts.dropFirst(2).joined(separator: ".")
        }
        return label
    }

    var status: JobStatus {
        if !isLoaded { return .unloaded }
        if let code = lastExitCode, code != 0 { return .failed }
        if pid != nil && pid != 0 { return .running }
        return .idle
    }
}

enum JobStatus: String {
    case running = "Running"
    case idle = "Idle"
    case failed = "Failed"
    case unloaded = "Unloaded"
}

enum JobSchedule: Hashable {
    case interval(seconds: Int)
    case calendar(entries: [CalendarEntry])
    case unknown

    struct CalendarEntry: Hashable {
        var month: Int?
        var day: Int?
        var weekday: Int?
        var hour: Int?
        var minute: Int?
    }

    var displayString: String {
        switch self {
        case .interval(let seconds):
            if seconds < 60 { return "Every \(seconds)s" }
            if seconds < 3600 { return "Every \(seconds / 60)m" }
            if seconds < 86400 { return "Every \(seconds / 3600)h" }
            return "Every \(seconds / 86400)d"
        case .calendar(let entries):
            guard let first = entries.first else { return "Calendar" }
            var parts: [String] = []
            if let w = first.weekday {
                let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                if w >= 1 && w <= 7 { parts.append(days[w]) }
            }
            if let h = first.hour {
                let m = first.minute ?? 0
                parts.append(String(format: "%d:%02d", h, m))
            }
            if entries.count > 1 {
                parts.append("(\(entries.count) schedules)")
            }
            return parts.isEmpty ? "Calendar" : parts.joined(separator: " ")
        case .unknown:
            return "Unknown"
        }
    }
}
