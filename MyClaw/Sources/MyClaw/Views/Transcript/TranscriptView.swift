import SwiftUI

struct TranscriptView: View {
    let session: SessionRun
    @State private var entries: [TranscriptEntry] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcript")
                        .font(.headline)
                    Text("\(session.projectName) — \(session.shortSessionId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let date = session.finishedDate {
                    Text(DateFormatting.dateTimeString(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            if isLoading {
                Spacer()
                ProgressView("Loading transcript...")
                Spacer()
            } else if entries.isEmpty {
                Spacer()
                Text("No transcript entries found.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(entries) { entry in
                            MessageBubble(entry: entry)
                        }
                    }
                    .padding()
                }
            }

            // Footer with token summary
            if !entries.isEmpty {
                Divider()
                TranscriptFooter(session: session, entries: entries)
            }
        }
        .task {
            entries = await loadTranscript()
            isLoading = false
        }
    }

    private func loadTranscript() async -> [TranscriptEntry] {
        TranscriptParser.parse(at: session.transcriptPath)
    }
}

struct TranscriptFooter: View {
    let session: SessionRun
    let entries: [TranscriptEntry]

    private var totalInput: Int {
        entries.compactMap(\.usage).reduce(0) { $0 + $1.inputTokens }
    }
    private var totalOutput: Int {
        entries.compactMap(\.usage).reduce(0) { $0 + $1.outputTokens }
    }

    var body: some View {
        HStack(spacing: 20) {
            Label("\(entries.filter(\.isUserMessage).count) messages", systemImage: "person")
            Label("\(entries.filter(\.isAssistantMessage).count) responses", systemImage: "cpu")
            Label("\(entries.filter(\.isToolRelated).count) tool calls", systemImage: "wrench")
            Spacer()
            if totalInput > 0 || totalOutput > 0 {
                Text("Input: \(DateFormatting.tokenString(totalInput)) / Output: \(DateFormatting.tokenString(totalOutput))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
