import SwiftUI

struct MessageBubble: View {
    let entry: TranscriptEntry

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if entry.isUserMessage {
                Spacer(minLength: 60)
            }

            VStack(alignment: entry.isUserMessage ? .trailing : .leading, spacing: 4) {
                // Timestamp
                if let ts = entry.timestamp {
                    Text(DateFormatting.timeString(from: ts))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Content
                switch entry.content {
                case .text(let text):
                    Text(text)
                        .textSelection(.enabled)
                        .padding(10)
                        .background(bubbleBackground)
                        .cornerRadius(12)

                case .toolCall(let tc):
                    ToolCallCard(toolCall: tc)

                case .toolResult(let tr):
                    ToolResultCard(result: tr)

                case .contentBlocks(let blocks):
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                            if block.type == "text", let text = block.text {
                                Text(text)
                                    .textSelection(.enabled)
                            } else if block.type == "tool_use", let tc = block.toolCall {
                                ToolCallCard(toolCall: tc)
                            }
                        }
                    }
                    .padding(10)
                    .background(bubbleBackground)
                    .cornerRadius(12)
                }

                // Token usage
                if let usage = entry.usage {
                    Text("in: \(DateFormatting.tokenString(usage.inputTokens)) / out: \(DateFormatting.tokenString(usage.outputTokens))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !entry.isUserMessage {
                Spacer(minLength: 60)
            }
        }
    }

    private var bubbleBackground: Color {
        switch entry.type {
        case .user: return .blue.opacity(0.15)
        case .assistant: return .primary.opacity(0.06)
        case .toolUse, .toolResult: return .orange.opacity(0.1)
        default: return .primary.opacity(0.04)
        }
    }
}
