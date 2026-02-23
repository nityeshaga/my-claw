import SwiftUI

struct StatsBarView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        HStack(spacing: 0) {
            StatCard(
                title: "Scheduled Jobs",
                value: "\(dataStore.jobs.count)",
                icon: "clock.badge.checkmark",
                color: .blue
            )
            Divider().frame(height: 40)
            StatCard(
                title: "Sessions Today",
                value: "\(dataStore.sessionsToday.count)",
                icon: "text.bubble",
                color: .green
            )
            Divider().frame(height: 40)
            StatCard(
                title: "Success Rate",
                value: String(format: "%.0f%%", dataStore.successRateToday * 100),
                icon: "checkmark.circle",
                color: dataStore.successRateToday >= 0.9 ? .green : .orange
            )
            Divider().frame(height: 40)
            StatCard(
                title: "Tokens Today",
                value: DateFormatting.tokenString(dataStore.totalTokensToday),
                icon: "number",
                color: .purple
            )
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
