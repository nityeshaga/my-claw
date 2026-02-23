import Foundation

/// Date parsing and formatting utilities
enum DateFormatting {
    private static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    /// Parse ISO 8601 string (with or without fractional seconds)
    static func parseISO8601(_ string: String) -> Date? {
        iso8601Full.date(from: string) ?? iso8601Basic.date(from: string)
    }

    /// "2 min ago", "3h ago", etc.
    static func relativeString(from date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: .now)
    }

    /// "3:45 PM"
    static func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// "Feb 24, 2026 at 3:45 PM"
    static func dateTimeString(from date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// "Mon", "Tue", etc.
    static func dayOfWeek(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// Format duration in seconds to "2m 30s" or "1h 5m"
    static func durationString(seconds: TimeInterval) -> String {
        let total = Int(seconds)
        if total < 60 { return "\(total)s" }
        if total < 3600 {
            let m = total / 60
            let s = total % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        }
        let h = total / 3600
        let m = (total % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    /// Format token count: "28K", "1.2M"
    static func tokenString(_ count: Int) -> String {
        if count < 1000 { return "\(count)" }
        if count < 1_000_000 {
            let k = Double(count) / 1000.0
            return k < 10 ? String(format: "%.1fK", k) : "\(Int(k))K"
        }
        let m = Double(count) / 1_000_000.0
        return String(format: "%.1fM", m)
    }
}
