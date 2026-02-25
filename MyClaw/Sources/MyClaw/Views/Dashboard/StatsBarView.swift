import SwiftUI

struct StatsBarView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        HStack(spacing: 2) {
            StatCard(
                title: "JOBS",
                value: "\(dataStore.jobs.count)",
                icon: "clock.badge.checkmark",
                color: Theme.neonCyan
            )
            StatCard(
                title: "TODAY",
                value: "\(dataStore.sessionsToday.count)",
                icon: "text.bubble",
                color: Theme.success
            )
            StatCard(
                title: "SUCCESS",
                value: String(format: "%.0f%%", dataStore.successRateToday * 100),
                icon: "checkmark.circle",
                color: dataStore.successRateToday >= 0.9 ? Theme.success : Theme.warning
            )
            StatCard(
                title: "TOKENS",
                value: DateFormatting.tokenString(dataStore.totalTokensToday),
                icon: "number",
                color: Theme.neonAmber
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.6), radius: 8)

            Text(value)
                .font(Theme.scoreFont)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 6)

            Text(title)
                .font(Theme.codeMono)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
