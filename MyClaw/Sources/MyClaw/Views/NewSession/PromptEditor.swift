import SwiftUI

struct PromptEditor: View {
    @Binding var prompt: String
    @Binding var workingDirectory: String
    @Binding var allowedTools: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Prompt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Working Directory")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("~/path/to/project (optional)", text: $workingDirectory)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Allowed Tools")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("tool1, tool2, ... (optional)", text: $allowedTools)
                        .textFieldStyle(.roundedBorder)
                    Text("Comma-separated list of tool names")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
    }
}
