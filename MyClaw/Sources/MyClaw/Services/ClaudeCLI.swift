import Foundation

/// Invokes the Claude CLI and streams output
@MainActor
class ClaudeCLI: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning = false
    @Published var exitCode: Int32?

    private var process: Process?
    private let settings = AppSettings.shared

    /// Run claude -p with the given prompt and configuration
    func run(prompt: String, workingDirectory: String? = nil, allowedTools: [String]? = nil) {
        stop()
        output = ""
        isRunning = true
        exitCode = nil

        let process = Process()
        process.executableURL = URL(fileURLWithPath: settings.claudeBinaryPath)

        var args = ["-p", prompt]
        if let tools = allowedTools, !tools.isEmpty {
            args += ["--allowedTools", tools.joined(separator: ",")]
        }
        process.arguments = args

        if let cwd = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.output += text
            }
        }

        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                self?.isRunning = false
                self?.exitCode = proc.terminationStatus
            }
        }

        do {
            try process.run()
            self.process = process
        } catch {
            output = "Failed to launch claude: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
    }
}
