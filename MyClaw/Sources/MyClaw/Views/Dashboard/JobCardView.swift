import SwiftUI

struct JobCardView: View {
    let job: Job

    private var statusColor: Color {
        StatusColor.forJobStatus(job.status)
    }

    private var isRunning: Bool {
        job.status == .running
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusDot(
                    color: statusColor,
                    size: 10,
                    isPulsing: isRunning
                )
                Text(job.name)
                    .font(Theme.headingMono)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                ArcadeBadge(text: job.status.rawValue, color: statusColor)
            }

            HStack {
                Image(systemName: "clock")
                    .font(Theme.captionMono)
                    .foregroundStyle(statusColor.opacity(0.6))
                Text(job.schedule.displayString)
                    .font(Theme.captionMono)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let exitCode = job.lastExitCode {
                HStack {
                    Image(systemName: exitCode == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(Theme.captionMono)
                        .foregroundStyle(StatusColor.forExitCode(exitCode))
                    Text("Last exit: \(exitCode)")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if let prompt = job.prompt {
                Text(prompt.prefix(80) + (prompt.count > 80 ? "..." : ""))
                    .font(Theme.codeMono)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding()
        .statusCard(statusColor, isActive: isRunning)
    }
}
