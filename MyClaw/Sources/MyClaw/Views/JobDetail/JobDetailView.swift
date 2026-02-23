import SwiftUI

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showRunConfirm = false

    var associatedSessions: [SessionRun] {
        dataStore.sessions(for: job)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Job header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(StatusColor.forJobStatus(job.status))
                                .frame(width: 10, height: 10)
                            Text(job.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(job.status.rawValue)
                                .font(.caption)
                                .foregroundStyle(StatusColor.forJobStatus(job.status))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(StatusColor.forJobStatus(job.status).opacity(0.1), in: Capsule())
                        }
                        Text(job.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button("Run Now") {
                            showRunConfirm = true
                        }
                        Button("Close") { dismiss() }
                            .keyboardShortcut(.escape)
                        .alert("Run \(job.name) now?", isPresented: $showRunConfirm) {
                            Button("Run") {
                                _ = LaunchdManager.start(label: job.label)
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }

                // Metadata grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                    MetadataRow(label: "Schedule", value: job.schedule.displayString)
                    MetadataRow(label: "Exit Code", value: job.lastExitCode.map(String.init) ?? "N/A")
                    if let cwd = job.workingDirectory {
                        MetadataRow(label: "Directory", value: cwd)
                    }
                    if let tools = job.allowedTools, !tools.isEmpty {
                        MetadataRow(label: "Tools", value: tools.joined(separator: ", "))
                    }
                }

                // Prompt
                if let prompt = job.prompt {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prompt")
                            .font(.headline)
                        Text(prompt)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Associated sessions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Run History (\(associatedSessions.count) sessions)")
                        .font(.headline)

                    if associatedSessions.isEmpty {
                        Text("No sessions found for this job's working directory.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        RunHistoryTable(sessions: associatedSessions)
                    }
                }

                // Charts
                if !associatedSessions.isEmpty {
                    RunCharts(sessions: associatedSessions)
                }
            }
            .padding()
        }
        .navigationTitle(job.name)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}
