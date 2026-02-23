import Foundation

/// Parses .jsonl transcript files into structured TranscriptEntry objects
enum TranscriptParser {
    /// Parse a full transcript file
    static func parse(at path: String) -> [TranscriptEntry] {
        let rawEntries = JSONLParser.parseRaw(from: path)
        return rawEntries.compactMap { parseEntry($0) }
    }

    private static func parseEntry(_ dict: [String: Any]) -> TranscriptEntry? {
        guard let type = dict["type"] as? String else { return nil }

        let timestamp: Date?
        if let ts = dict["timestamp"] as? String {
            timestamp = DateFormatting.parseISO8601(ts)
        } else {
            timestamp = nil
        }

        // Skip queue operations and system messages
        guard type == "user" || type == "assistant" else { return nil }

        guard let message = dict["message"] as? [String: Any] else { return nil }
        let role = message["role"] as? String

        // Check if this is a tool result (user message with tool_result content)
        if type == "user", let contentArray = message["content"] as? [[String: Any]],
           let first = contentArray.first, first["type"] as? String == "tool_result" {
            let toolUseId = first["tool_use_id"] as? String ?? ""
            let resultContent = first["content"] as? String ?? ""
            let isError = first["is_error"] as? Bool ?? false
            return TranscriptEntry(
                type: .toolResult,
                timestamp: timestamp,
                content: .toolResult(TranscriptEntry.ToolResultData(
                    toolUseId: toolUseId,
                    content: resultContent,
                    isError: isError
                )),
                usage: nil
            )
        }

        // User text message
        if type == "user" {
            let text: String
            if let s = message["content"] as? String {
                text = s
            } else {
                text = ""
            }
            guard !text.isEmpty else { return nil }
            return TranscriptEntry(type: .user, timestamp: timestamp, content: .text(text), usage: nil)
        }

        // Assistant message — may contain text, tool_use, thinking blocks
        if type == "assistant", role == "assistant" {
            let usage = parseUsage(from: message)

            if let contentArray = message["content"] as? [[String: Any]] {
                var blocks: [TranscriptEntry.ContentBlock] = []

                for block in contentArray {
                    let blockType = block["type"] as? String ?? "unknown"

                    switch blockType {
                    case "text":
                        let text = block["text"] as? String ?? ""
                        if !text.isEmpty {
                            blocks.append(TranscriptEntry.ContentBlock(type: "text", text: text, toolCall: nil))
                        }
                    case "tool_use":
                        let toolId = block["id"] as? String ?? ""
                        let name = block["name"] as? String ?? ""
                        let input = block["input"] as? [String: Any] ?? [:]
                        let tc = TranscriptEntry.ToolCall(toolId: toolId, name: name, input: input)
                        blocks.append(TranscriptEntry.ContentBlock(type: "tool_use", text: nil, toolCall: tc))
                    case "thinking":
                        // Skip thinking blocks — they're internal
                        continue
                    default:
                        continue
                    }
                }

                guard !blocks.isEmpty else { return nil }

                // If it's just tool calls, mark as toolUse type
                if blocks.allSatisfy({ $0.type == "tool_use" }), let tc = blocks.first?.toolCall {
                    return TranscriptEntry(type: .toolUse, timestamp: timestamp, content: .toolCall(tc), usage: usage)
                }

                return TranscriptEntry(type: .assistant, timestamp: timestamp, content: .contentBlocks(blocks), usage: usage)
            }

            // Simple string content
            if let text = message["content"] as? String, !text.isEmpty {
                return TranscriptEntry(type: .assistant, timestamp: timestamp, content: .text(text), usage: usage)
            }

            return nil
        }

        return nil
    }

    private static func parseUsage(from message: [String: Any]) -> TranscriptEntry.Usage? {
        guard let usage = message["usage"] as? [String: Any] else { return nil }
        let input = usage["input_tokens"] as? Int ?? 0
        let output = usage["output_tokens"] as? Int ?? 0
        let cacheCreate = usage["cache_creation_input_tokens"] as? Int ?? 0
        let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
        guard input > 0 || output > 0 else { return nil }
        return TranscriptEntry.Usage(
            inputTokens: input,
            outputTokens: output,
            cacheCreationTokens: cacheCreate,
            cacheReadTokens: cacheRead
        )
    }
}
