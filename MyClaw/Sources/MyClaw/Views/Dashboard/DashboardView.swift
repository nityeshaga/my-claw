import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StatsBarView()

                if !dataStore.jobs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scheduled Jobs")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                            ForEach(dataStore.jobs) { job in
                                JobCardView(job: job)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                    if dataStore.sessions.isEmpty {
                        Text("No sessions captured yet.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        SessionListView(sessions: Array(dataStore.sessions.prefix(20)))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dataStore.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
    }
}
