import SwiftUI

struct JobEditorSheet: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var prompt = ""
    @State private var workingDirectory = ""
    @State private var allowedTools = ""
    @State private var scheduleType: ScheduleType = .interval
    @State private var intervalMinutes = 30
    @State private var calendarHour = 9
    @State private var calendarMinute = 0
    @State private var selectedWeekdays: Set<Int> = []
    @State private var errorMessage: String?

    enum ScheduleType: String, CaseIterable {
        case interval = "Every N minutes"
        case daily = "Daily at time"
        case weekdays = "Specific days"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Scheduled Job")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Job Name")
                            .font(.subheadline).fontWeight(.medium)
                        TextField("my-job-name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        Text("Lowercase, hyphens only. Used in filenames.")
                            .font(.caption).foregroundStyle(.tertiary)
                    }

                    // Prompt
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompt")
                            .font(.subheadline).fontWeight(.medium)
                        TextEditor(text: $prompt)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
                    }

                    // Working directory
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Working Directory")
                            .font(.subheadline).fontWeight(.medium)
                        TextField("/path/to/project", text: $workingDirectory)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Schedule
                    SchedulePicker(
                        scheduleType: $scheduleType,
                        intervalMinutes: $intervalMinutes,
                        calendarHour: $calendarHour,
                        calendarMinute: $calendarMinute,
                        selectedWeekdays: $selectedWeekdays
                    )

                    // Tools
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allowed Tools (optional)")
                            .font(.subheadline).fontWeight(.medium)
                        TextField("tool1, tool2, ...", text: $allowedTools)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Create & Load") { createJob() }
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !prompt.isEmpty && !workingDirectory.isEmpty
    }

    private func createJob() {
        let sanitizedName = name.lowercased().replacingOccurrences(of: " ", with: "-")

        let schedule: JobSchedule
        switch scheduleType {
        case .interval:
            schedule = .interval(seconds: intervalMinutes * 60)
        case .daily:
            schedule = .calendar(entries: [
                JobSchedule.CalendarEntry(hour: calendarHour, minute: calendarMinute)
            ])
        case .weekdays:
            let entries = selectedWeekdays.sorted().map { day in
                JobSchedule.CalendarEntry(weekday: day, hour: calendarHour, minute: calendarMinute)
            }
            schedule = entries.isEmpty
                ? .calendar(entries: [JobSchedule.CalendarEntry(hour: calendarHour, minute: calendarMinute)])
                : .calendar(entries: entries)
        }

        let tools = allowedTools.isEmpty ? nil : allowedTools.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard let result = LaunchdManager.createJob(
            name: sanitizedName,
            prompt: prompt,
            workingDirectory: workingDirectory,
            schedule: schedule,
            allowedTools: tools
        ) else {
            errorMessage = "Failed to create job files."
            return
        }

        // Load into launchd
        if !LaunchdManager.load(plistPath: result.plistPath) {
            errorMessage = "Job files created but failed to load into launchd."
            return
        }

        onSave()
        dismiss()
    }
}
