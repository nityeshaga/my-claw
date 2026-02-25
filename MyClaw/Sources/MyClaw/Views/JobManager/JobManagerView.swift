import SwiftUI

struct JobManagerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showEditor = false
    @State private var selectedJob: Job?
    @State private var showDeleteConfirm = false
    @State private var jobToDelete: Job?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dataStore.jobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(Theme.displayMono)
                        .foregroundStyle(Theme.textTertiary)
                    Text("No Scheduled Jobs")
                        .font(Theme.headingMono)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Create a job to run Claude on a schedule.")
                        .font(Theme.bodyText)
                        .foregroundStyle(Theme.textSecondary)
                    Button("Create Job") { showEditor = true }
                        .tint(Theme.coral)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(dataStore.jobs) { job in
                        JobManagerRow(job: job, onDetail: {
                            selectedJob = job
                        }, onToggle: {
                            toggleJob(job)
                        }, onDelete: {
                            jobToDelete = job
                            showDeleteConfirm = true
                        })
                    }
                }
            }
        }
        .navigationTitle("Scheduled Jobs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Create new job")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dataStore.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .sheet(isPresented: $showEditor) {
            JobEditorSheet { dataStore.refresh() }
                .frame(minWidth: 500, minHeight: 400)
        }
        .sheet(item: $selectedJob) { job in
            JobDetailView(job: job)
                .environmentObject(dataStore)
                .frame(minWidth: 700, minHeight: 500)
        }
        .alert("Delete \(jobToDelete?.name ?? "job")?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let job = jobToDelete {
                    _ = LaunchdManager.deleteJob(job: job)
                    dataStore.refresh()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will unload the job and remove its script and plist files.")
        }
    }

    private func toggleJob(_ job: Job) {
        if job.isLoaded {
            _ = LaunchdManager.unload(plistPath: job.plistPath)
        } else {
            _ = LaunchdManager.load(plistPath: job.plistPath)
        }
        dataStore.refresh()
    }
}

struct JobManagerRow: View {
    let job: Job
    let onDetail: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(
                color: StatusColor.forJobStatus(job.status),
                size: 8,
                isPulsing: job.status == .running
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(job.name)
                    .font(Theme.headingMono)
                    .foregroundStyle(Theme.textPrimary)
                Text(job.schedule.displayString)
                    .font(Theme.captionMono)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { job.isLoaded },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .tint(Theme.success)
            .labelsHidden()

            Button { onDetail() } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.neonCyan)
            }
            .buttonStyle(.borderless)

            Button { onDelete() } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.error)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
