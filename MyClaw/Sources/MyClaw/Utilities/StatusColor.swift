import SwiftUI

/// Status-to-color mapping using the arcade theme palette
enum StatusColor {
    static func forJobStatus(_ status: JobStatus) -> Color {
        switch status {
        case .running: return Theme.neonCyan
        case .idle: return Theme.success
        case .failed: return Theme.error
        case .unloaded: return Theme.textTertiary
        }
    }

    static func forExitCode(_ code: Int?) -> Color {
        guard let code else { return Theme.textTertiary }
        return code == 0 ? Theme.success : Theme.error
    }

    static func forReason(_ reason: String) -> Color {
        switch reason {
        case "error": return Theme.error
        case "other": return Theme.success
        case "prompt_input_exit": return Theme.warning
        case "clear": return Theme.textTertiary
        default: return Theme.success
        }
    }

    static func menuBarTint(jobs: [Job], recentSessions: [SessionRun]) -> Color {
        if jobs.isEmpty && recentSessions.isEmpty { return Theme.textTertiary }
        let hasRecentFailure = recentSessions.prefix(5).contains { !$0.isSuccess }
        if hasRecentFailure { return Theme.error }
        return Theme.success
    }
}
