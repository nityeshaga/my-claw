import Foundation

/// A single entry from a transcript .jsonl file
struct TranscriptEntry: Identifiable {
    let id = UUID()
    let type: EntryType
    let timestamp: Date?
    let content: EntryContent

    enum EntryType: String {
        case user
        case assistant
        case toolUse
        case toolResult
        case system
        case unknown
    }

    enum EntryContent {
        case text(String)
        case toolCall(ToolCall)
        case toolResult(ToolResultData)
        case contentBlocks([ContentBlock])
    }

    struct ToolCall {
        let toolId: String
        let name: String
        let input: [String: Any]

        var inputSummary: String {
            if let cmd = input["command"] as? String {
                return cmd.count > 100 ? String(cmd.prefix(100)) + "..." : cmd
            }
            if let path = input["file_path"] as? String {
                return path
            }
            if let pattern = input["pattern"] as? String {
                return pattern
            }
            let keys = input.keys.sorted().joined(separator: ", ")
            return keys.isEmpty ? "(no input)" : keys
        }
    }

    struct ToolResultData {
        let toolUseId: String
        let content: String
        let isError: Bool
    }

    struct ContentBlock {
        let type: String // "text", "thinking", "tool_use"
        let text: String?
        let toolCall: ToolCall?
    }

    struct Usage {
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationTokens: Int
        let cacheReadTokens: Int
    }

    var usage: Usage?

    var isUserMessage: Bool { type == .user }
    var isAssistantMessage: Bool { type == .assistant }
    var isToolRelated: Bool { type == .toolUse || type == .toolResult }

    /// Extract plain text from the entry
    var plainText: String {
        switch content {
        case .text(let s): return s
        case .toolCall(let tc): return "[\(tc.name)] \(tc.inputSummary)"
        case .toolResult(let tr): return tr.content
        case .contentBlocks(let blocks):
            return blocks.compactMap { $0.text }.joined(separator: "\n")
        }
    }
}
