import SwiftUI
import Charts

struct TimelineView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Activity")
                .font(.headline)

            if chartData.isEmpty {
                Text("No session data available.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
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
        // Pre-fill all 7 days
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
