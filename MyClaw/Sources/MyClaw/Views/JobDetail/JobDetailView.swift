import SwiftUI

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showRunConfirm = false

    var associatedSessions: [SessionRun] {
        dataStore.sessions(for: job)
    }

    private var statusColor: Color {
        StatusColor.forJobStatus(job.status)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Job header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            StatusDot(
                                color: statusColor,
                                size: 10,
                                isPulsing: job.status == .running
                            )
                            Text(job.name)
                                .font(Theme.titleMono)
                                .foregroundStyle(Theme.textPrimary)
                            ArcadeBadge(text: job.status.rawValue, color: statusColor)
                        }
                        Text(job.label)
                            .font(Theme.captionMono)
                            .foregroundStyle(Theme.textTertiary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button("Run Now") {
                            showRunConfirm = true
                        }
                        .tint(Theme.coral)
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
                            .font(Theme.headingMono)
                            .foregroundStyle(Theme.textSecondary)
                        Text(prompt)
                            .font(Theme.bodyText)
                            .foregroundStyle(Theme.textSecondary)
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surfaceInput, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                }

                // Associated sessions
                VStack(alignment: .leading, spacing: 12) {
                    ArcadeSectionHeader(title: "Run History (\(associatedSessions.count) sessions)", color: Theme.neonCyan)

                    if associatedSessions.isEmpty {
                        Text("No sessions found for this job's working directory.")
                            .font(Theme.bodyText)
                            .foregroundStyle(Theme.textTertiary)
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
        .background(Theme.bgDeep)
        .preferredColorScheme(.dark)
        .navigationTitle(job.name)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.captionMono)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(Theme.dataMono)
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}
