import SwiftUI
import Charts

struct RunCharts: View {
    let sessions: [SessionRun]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ArcadeSectionHeader(title: "Trends", color: Theme.neonAmber)

            HStack(spacing: 16) {
                // Token usage chart
                VStack(alignment: .leading, spacing: 6) {
                    Text("Token Usage")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                    Chart(chartSessions, id: \.sessionId) { session in
                        BarMark(
                            x: .value("Session", session.shortSessionId),
                            y: .value("Tokens", session.totalTokens)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.neonAmber, Theme.neonPurple],
                                startPoint: .bottom, endPoint: .top
                            )
                        )
                        .cornerRadius(3)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(Theme.codeMono)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel()
                                .font(Theme.codeMono)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding()
                .arcadeCard(borderColor: Theme.neonPurple.opacity(0.3))

                // Duration chart
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textTertiary)
                    Chart(chartSessions.filter { $0.durationSeconds != nil }, id: \.sessionId) { session in
                        BarMark(
                            x: .value("Session", session.shortSessionId),
                            y: .value("Seconds", session.durationSeconds ?? 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.neonCyan, Theme.success],
                                startPoint: .bottom, endPoint: .top
                            )
                        )
                        .cornerRadius(3)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(Theme.codeMono)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.08))
                            AxisValueLabel()
                                .font(Theme.codeMono)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding()
                .arcadeCard(borderColor: Theme.neonCyan.opacity(0.3))
            }
        }
    }

    private var chartSessions: [SessionRun] {
        Array(sessions.suffix(10).reversed())
    }
}
