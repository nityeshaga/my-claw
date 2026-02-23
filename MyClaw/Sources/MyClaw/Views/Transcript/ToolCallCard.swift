import SwiftUI

struct ToolCallCard: View {
    let toolCall: TranscriptEntry.ToolCall
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(toolCall.name)
                        .font(.callout)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Text(toolCall.inputSummary)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 2)

            if isExpanded {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(formatInput(toolCall.input))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(10)
        .background(.orange.opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatInput(_ input: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: input, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: input)
        }
        return string
    }
}

struct ToolResultCard: View {
    let result: TranscriptEntry.ToolResultData
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: result.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(result.isError ? .red : .green)
                    Text("Result")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(result.content)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(8)
        .background(.primary.opacity(0.03))
        .cornerRadius(6)
    }
}
