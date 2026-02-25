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
                        .font(Theme.headingMono)
                        .foregroundStyle(Theme.textSecondary)
                    TextEditor(text: $prompt)
                        .font(Theme.bodyText)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Theme.surfaceInput, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Working Directory")
                        .font(Theme.headingMono)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("~/path/to/project (optional)", text: $workingDirectory)
                        .font(Theme.dataMono)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Allowed Tools")
                        .font(Theme.headingMono)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("tool1, tool2, ... (optional)", text: $allowedTools)
                        .font(Theme.dataMono)
                        .textFieldStyle(.roundedBorder)
                    Text("Comma-separated list of tool names")
                        .font(Theme.codeMono)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding()
        }
    }
}
