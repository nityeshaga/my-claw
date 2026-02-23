import SwiftUI

struct SchedulePicker: View {
    @Binding var scheduleType: JobEditorSheet.ScheduleType
    @Binding var intervalMinutes: Int
    @Binding var calendarHour: Int
    @Binding var calendarMinute: Int
    @Binding var selectedWeekdays: Set<Int>

    private let weekdayNames = [
        (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"), (5, "Fri"), (6, "Sat"), (7, "Sun")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.subheadline).fontWeight(.medium)

            Picker("Type", selection: $scheduleType) {
                ForEach(JobEditorSheet.ScheduleType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            switch scheduleType {
            case .interval:
                HStack {
                    Text("Every")
                    TextField("30", value: $intervalMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("minutes")
                }

            case .daily:
                HStack {
                    Text("At")
                    Picker("Hour", selection: $calendarHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h)).tag(h)
                        }
                    }
                    .frame(width: 60)
                    Text(":")
                    Picker("Minute", selection: $calendarMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .frame(width: 60)
                }

            case .weekdays:
                HStack {
                    Text("At")
                    Picker("Hour", selection: $calendarHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h)).tag(h)
                        }
                    }
                    .frame(width: 60)
                    Text(":")
                    Picker("Minute", selection: $calendarMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .frame(width: 60)
                }

                HStack(spacing: 6) {
                    ForEach(weekdayNames, id: \.0) { (day, name) in
                        Button {
                            if selectedWeekdays.contains(day) {
                                selectedWeekdays.remove(day)
                            } else {
                                selectedWeekdays.insert(day)
                            }
                        } label: {
                            Text(name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    selectedWeekdays.contains(day) ? Color.accentColor : Color.primary.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .foregroundStyle(selectedWeekdays.contains(day) ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
