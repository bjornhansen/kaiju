import Foundation

enum DateFormatters {
    /// ISO 8601 formatter for Jira API dates (e.g., "2024-01-15T10:30:00.000+0000")
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Formatter for displaying relative dates (e.g., "2 hours ago")
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Parse a Jira date string to Date
    static func parseJiraDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        // Try ISO8601 with fractional seconds first
        if let date = iso8601.date(from: string) {
            return date
        }
        // Fallback: ISO8601 without fractional seconds
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: string)
    }

    /// Format a date for Jira JQL queries
    static func jqlDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Format a date for display (e.g., "Jan 15, 2024 at 10:30 AM")
    static func displayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format a date as relative time (e.g., "2h ago")
    static func relativeString(from date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }

    /// Current time as ISO8601 string for sync state
    static func nowISO8601() -> String {
        iso8601.string(from: Date())
    }
}
