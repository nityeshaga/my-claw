import SwiftUI

struct NewSessionView: View {
    @StateObject private var cli = ClaudeCLI()
    @State private var prompt = ""
    @State private var workingDirectory = ""
    @State private var allowedTools = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Session")
                    .font(Theme.headingMono)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            if cli.isRunning || cli.exitCode != nil {
                LiveOutputView(cli: cli)
            } else {
                PromptEditor(
                    prompt: $prompt,
                    workingDirectory: $workingDirectory,
                    allowedTools: $allowedTools
                )
            }

            Divider()

            // Footer
            HStack {
                if let code = cli.exitCode {
                    Label(
                        code == 0 ? "Completed successfully" : "Exited with code \(code)",
                        systemImage: code == 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(code == 0 ? Theme.success : Theme.error)
                    .font(Theme.captionMono)
                }
                Spacer()
                if cli.isRunning {
                    Button("Stop") { cli.stop() }
                        .tint(Theme.error)
                } else if cli.exitCode == nil {
                    Button("Run") { launchSession() }
                        .tint(Theme.coral)
                        .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                } else {
                    Button("New Session") {
                        prompt = ""
                        cli.output = ""
                        cli.exitCode = nil
                    }
                    .tint(Theme.coral)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private func launchSession() {
        let tools = allowedTools.isEmpty ? nil : allowedTools.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let cwd = workingDirectory.isEmpty ? nil : workingDirectory
        cli.run(prompt: prompt, workingDirectory: cwd, allowedTools: tools)
    }
}
