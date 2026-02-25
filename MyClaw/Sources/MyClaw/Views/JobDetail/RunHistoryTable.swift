import SwiftUI

struct RunHistoryTable: View {
    let sessions: [SessionRun]
    @State private var sortOrder = [KeyPathComparator(\SessionRun.finishedAt, order: .reverse)]

    var sortedSessions: [SessionRun] {
        sessions.sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortedSessions, sortOrder: $sortOrder) {
            TableColumn("Session", value: \.sessionId) { session in
                HStack(spacing: 4) {
                    StatusDot(
                        color: StatusColor.forReason(session.reason),
                        size: 6
                    )
                    Text(session.shortSessionId)
                        .font(Theme.codeMono)
                }
            }
            .width(min: 80, max: 100)

            TableColumn("Turns") { session in
                Text(session.numTurns.map(String.init) ?? "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.textSecondary)
            }
            .width(50)

            TableColumn("Tokens") { session in
                Text(session.totalTokens > 0 ? DateFormatting.tokenString(session.totalTokens) : "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.neonAmber.opacity(0.8))
            }
            .width(70)

            TableColumn("Duration") { session in
                Text(session.durationSeconds.map { DateFormatting.durationString(seconds: $0) } ?? "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.textSecondary)
            }
            .width(80)

            TableColumn("Finished", value: \.finishedAt) { session in
                if let date = session.finishedDate {
                    Text(DateFormatting.relativeString(from: date))
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    Text("-")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .width(min: 80, max: 120)

            TableColumn("Reason") { session in
                ArcadeBadge(text: session.reason, color: StatusColor.forReason(session.reason))
            }
            .width(70)
        }
        .frame(minHeight: 200, maxHeight: 400)
    }
}
