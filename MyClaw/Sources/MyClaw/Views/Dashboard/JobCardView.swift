import SwiftUI

struct JobCardView: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(StatusColor.forJobStatus(job.status))
                    .frame(width: 8, height: 8)
                Text(job.name)
                    .font(.headline)
                Spacer()
                Text(job.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(StatusColor.forJobStatus(job.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(StatusColor.forJobStatus(job.status).opacity(0.1), in: Capsule())
            }

            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(job.schedule.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let exitCode = job.lastExitCode {
                HStack {
                    Image(systemName: exitCode == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(StatusColor.forExitCode(exitCode))
                    Text("Last exit: \(exitCode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let prompt = job.prompt {
                Text(prompt.prefix(80) + (prompt.count > 80 ? "..." : ""))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}
