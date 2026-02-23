import SwiftUI

/// Status-to-color mapping for consistent UI
enum StatusColor {
    static func forJobStatus(_ status: JobStatus) -> Color {
        switch status {
        case .running: return .blue
        case .idle: return .green
        case .failed: return .red
        case .unloaded: return .secondary
        }
    }

    static func forExitCode(_ code: Int?) -> Color {
        guard let code else { return .secondary }
        return code == 0 ? .green : .red
    }

    static func forReason(_ reason: String) -> Color {
        switch reason {
        case "error": return .red
        case "other": return .green
        case "prompt_input_exit": return .orange
        case "clear": return .secondary
        default: return .green
        }
    }

    static func menuBarTint(jobs: [Job], recentSessions: [SessionRun]) -> Color {
        if jobs.isEmpty && recentSessions.isEmpty { return .secondary }
        let hasRecentFailure = recentSessions.prefix(5).contains { !$0.isSuccess }
        if hasRecentFailure { return .red }
        return .green
    }
}
