import SwiftUI
import Charts

struct TimelineView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArcadeSectionHeader(title: "7-Day Activity", color: Theme.neonPurple)

            if chartData.isEmpty {
                Text("No session data available.")
                    .font(Theme.bodyText)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.neonCyan, Theme.neonPurple],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(height: 140)
            }
        }
        .padding()
        .arcadeCard(borderColor: Theme.neonPurple.opacity(0.25))
    }

    private var chartData: [DayCount] {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let recentSessions = dataStore.sessions.filter { session in
            guard let date = session.finishedDate else { return false }
            return date >= sevenDaysAgo
        }

        var countsByDay: [Date: Int] = [:]
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                countsByDay[dayStart] = 0
            }
        }

        for session in recentSessions {
            guard let date = session.finishedDate else { continue }
            let dayStart = calendar.startOfDay(for: date)
            countsByDay[dayStart, default: 0] += 1
        }

        return countsByDay.map { DayCount(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

private struct DayCount {
    let date: Date
    let count: Int
}
