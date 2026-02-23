import Foundation

/// Parses launchd plist files to extract schedule info
enum PlistParser {
    struct PlistData {
        let label: String
        let scriptPath: String
        let schedule: JobSchedule
        let runAtLoad: Bool
    }

    /// Parse a launchd plist file
    static func parse(at path: String) -> PlistData? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        guard let label = plist["Label"] as? String else { return nil }

        let scriptPath: String
        if let args = plist["ProgramArguments"] as? [String], let first = args.first {
            scriptPath = first
        } else if let program = plist["Program"] as? String {
            scriptPath = program
        } else {
            return nil
        }

        let schedule = parseSchedule(from: plist)
        let runAtLoad = plist["RunAtLoad"] as? Bool ?? false

        return PlistData(label: label, scriptPath: scriptPath, schedule: schedule, runAtLoad: runAtLoad)
    }

    private static func parseSchedule(from plist: [String: Any]) -> JobSchedule {
        if let interval = plist["StartInterval"] as? Int {
            return .interval(seconds: interval)
        }

        if let calDict = plist["StartCalendarInterval"] {
            if let single = calDict as? [String: Any] {
                return .calendar(entries: [parseCalendarEntry(single)])
            }
            if let array = calDict as? [[String: Any]] {
                return .calendar(entries: array.map { parseCalendarEntry($0) })
            }
        }

        return .unknown
    }

    private static func parseCalendarEntry(_ dict: [String: Any]) -> JobSchedule.CalendarEntry {
        JobSchedule.CalendarEntry(
            month: dict["Month"] as? Int,
            day: dict["Day"] as? Int,
            weekday: dict["Weekday"] as? Int,
            hour: dict["Hour"] as? Int,
            minute: dict["Minute"] as? Int
        )
    }
}
