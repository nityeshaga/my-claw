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
                    Circle()
                        .fill(StatusColor.forReason(session.reason))
                        .frame(width: 6, height: 6)
                    Text(session.shortSessionId)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .width(min: 80, max: 100)

            TableColumn("Turns") { session in
                Text(session.numTurns.map(String.init) ?? "-")
            }
            .width(50)

            TableColumn("Tokens") { session in
                Text(session.totalTokens > 0 ? DateFormatting.tokenString(session.totalTokens) : "-")
            }
            .width(70)

            TableColumn("Duration") { session in
                Text(session.durationSeconds.map { DateFormatting.durationString(seconds: $0) } ?? "-")
            }
            .width(80)

            TableColumn("Finished", value: \.finishedAt) { session in
                if let date = session.finishedDate {
                    Text(DateFormatting.relativeString(from: date))
                } else {
                    Text("-")
                }
            }
            .width(min: 80, max: 120)

            TableColumn("Reason") { session in
                Text(session.reason)
                    .foregroundStyle(StatusColor.forReason(session.reason))
            }
            .width(70)
        }
        .frame(minHeight: 200, maxHeight: 400)
    }
}
