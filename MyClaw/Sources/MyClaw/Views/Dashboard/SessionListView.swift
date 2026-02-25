import SwiftUI

struct SessionListView: View {
    let sessions: [SessionRun]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SESSION")
                    .frame(width: 80, alignment: .leading)
                Text("PROJECT")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("TURNS")
                    .frame(width: 50, alignment: .trailing)
                Text("TOKENS")
                    .frame(width: 70, alignment: .trailing)
                Text("DURATION")
                    .frame(width: 80, alignment: .trailing)
                Text("FINISHED")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(Theme.codeMono)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                SessionRowView(session: session, isEven: index % 2 == 0)
            }
        }
        .arcadeCard(borderColor: Theme.coral.opacity(0.2))
    }
}

struct SessionRowView: View {
    let session: SessionRun
    let isEven: Bool
    @State private var showTranscript = false
    @State private var isHovered = false

    var body: some View {
        Button {
            showTranscript = true
        } label: {
            HStack {
                HStack(spacing: 6) {
                    StatusDot(
                        color: StatusColor.forReason(session.reason),
                        size: 8
                    )
                    Text(session.shortSessionId)
                        .font(Theme.codeMono)
                        .foregroundStyle(Theme.neonCyan)
                }
                .frame(width: 80, alignment: .leading)

                Text(session.projectName)
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(session.numTurns.map(String.init) ?? "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 50, alignment: .trailing)

                Text(session.totalTokens > 0 ? DateFormatting.tokenString(session.totalTokens) : "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.neonAmber)
                    .frame(width: 70, alignment: .trailing)

                Text(session.durationSeconds.map { DateFormatting.durationString(seconds: $0) } ?? "-")
                    .font(Theme.dataMono)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 80, alignment: .trailing)

                if let date = session.finishedDate {
                    Text(DateFormatting.relativeString(from: date))
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 100, alignment: .trailing)
                } else {
                    Text("-")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 100, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isHovered
                ? Theme.surfaceElevated
                : (isEven ? Color.white.opacity(0.02) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Theme.coral.opacity(isHovered ? 0.3 : 0), lineWidth: 1)
                .padding(.horizontal, 2)
        )
        .onHover { isHovered = $0 }
        .sheet(isPresented: $showTranscript) {
            TranscriptView(session: session)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}
