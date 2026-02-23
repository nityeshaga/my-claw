import SwiftUI

struct SessionListView: View {
    let sessions: [SessionRun]

    var body: some View {
        VStack(spacing: 1) {
            // Header
            HStack {
                Text("Session")
                    .frame(width: 80, alignment: .leading)
                Text("Project")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Turns")
                    .frame(width: 50, alignment: .trailing)
                Text("Tokens")
                    .frame(width: 70, alignment: .trailing)
                Text("Duration")
                    .frame(width: 80, alignment: .trailing)
                Text("Finished")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            ForEach(sessions) { session in
                SessionRowView(session: session)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

struct SessionRowView: View {
    let session: SessionRun
    @State private var showTranscript = false

    var body: some View {
        Button {
            showTranscript = true
        } label: {
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(StatusColor.forReason(session.reason))
                        .frame(width: 6, height: 6)
                    Text(session.shortSessionId)
                        .font(.system(.caption, design: .monospaced))
                }
                .frame(width: 80, alignment: .leading)

                Text(session.projectName)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(session.numTurns.map(String.init) ?? "-")
                    .frame(width: 50, alignment: .trailing)

                Text(session.totalTokens > 0 ? DateFormatting.tokenString(session.totalTokens) : "-")
                    .frame(width: 70, alignment: .trailing)

                Text(session.durationSeconds.map { DateFormatting.durationString(seconds: $0) } ?? "-")
                    .frame(width: 80, alignment: .trailing)

                if let date = session.finishedDate {
                    Text(DateFormatting.relativeString(from: date))
                        .frame(width: 100, alignment: .trailing)
                } else {
                    Text("-")
                        .frame(width: 100, alignment: .trailing)
                }
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.02))
        .sheet(isPresented: $showTranscript) {
            TranscriptView(session: session)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}
