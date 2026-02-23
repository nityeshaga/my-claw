import SwiftUI
import Charts

struct RunCharts: View {
    let sessions: [SessionRun]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.headline)

            HStack(spacing: 16) {
                // Token usage chart
                VStack(alignment: .leading, spacing: 6) {
                    Text("Token Usage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Chart(chartSessions, id: \.sessionId) { session in
                        BarMark(
                            x: .value("Session", session.shortSessionId),
                            y: .value("Tokens", session.totalTokens)
                        )
                        .foregroundStyle(.purple.gradient)
                        .cornerRadius(3)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.caption2)
                        }
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))

                // Duration chart
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Chart(chartSessions.filter { $0.durationSeconds != nil }, id: \.sessionId) { session in
                        BarMark(
                            x: .value("Session", session.shortSessionId),
                            y: .value("Seconds", session.durationSeconds ?? 0)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(3)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.caption2)
                        }
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
            }
        }
    }

    private var chartSessions: [SessionRun] {
        Array(sessions.suffix(10).reversed())
    }
}
