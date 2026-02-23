import Foundation

/// A single Claude session run, parsed from jobs-index.jsonl
struct SessionRun: Identifiable, Codable, Hashable {
    let sessionId: String
    let transcriptPath: String
    let cwd: String
    let reason: String
    let finishedAt: String
    var numTurns: Int?
    var startedAt: String?
    var totalInputTokens: Int?
    var totalOutputTokens: Int?

    var id: String { sessionId }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case transcriptPath = "transcript_path"
        case cwd
        case reason
        case finishedAt = "finished_at"
        case numTurns = "num_turns"
        case startedAt = "started_at"
        case totalInputTokens = "total_input_tokens"
        case totalOutputTokens = "total_output_tokens"
    }

    var finishedDate: Date? {
        DateFormatting.parseISO8601(finishedAt)
    }

    var startedDate: Date? {
        guard let s = startedAt else { return nil }
        return DateFormatting.parseISO8601(s)
    }

    var durationSeconds: TimeInterval? {
        guard let start = startedDate, let end = finishedDate else { return nil }
        return end.timeIntervalSince(start)
    }

    var totalTokens: Int {
        (totalInputTokens ?? 0) + (totalOutputTokens ?? 0)
    }

    var shortSessionId: String {
        String(sessionId.prefix(8))
    }

    var projectName: String {
        let url = URL(fileURLWithPath: cwd)
        return url.lastPathComponent
    }

    var isSuccess: Bool {
        reason != "error"
    }
}
