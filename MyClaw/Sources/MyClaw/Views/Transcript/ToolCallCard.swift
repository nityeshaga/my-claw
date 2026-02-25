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
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.neonAmber)
                    Text(toolCall.name)
                        .font(Theme.dataMono)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Theme.codeMono)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            Text(toolCall.inputSummary)
                .font(Theme.captionMono)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(isExpanded ? nil : 2)

            if isExpanded {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(formatInput(toolCall.input))
                        .font(Theme.codeMono)
                        .foregroundStyle(Theme.textTertiary)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(10)
        .background(Theme.neonAmber.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.neonAmber.opacity(0.15), lineWidth: 1)
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
                        .font(Theme.captionMono)
                        .foregroundStyle(result.isError ? Theme.error : Theme.success)
                    Text("Result")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Theme.codeMono)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(result.content)
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textSecondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
    }
}
