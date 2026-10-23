import Foundation

/// Date helpers for records that belong to a user's local calendar day.
/// Date-only records intentionally do not use UTC timestamps as their identity.
enum LocalDay {
    static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func key(for date: Date, calendar: Calendar = LocalDay.calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func date(from key: String, calendar: Calendar = LocalDay.calendar) -> Date? {
        let pieces = key.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3 else { return nil }

        return calendar.date(from: DateComponents(
            year: pieces[0],
            month: pieces[1],
            day: pieces[2]
        ))
    }

    static func startOfDay(for date: Date, calendar: Calendar = LocalDay.calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static func startOfMonth(for date: Date, calendar: Calendar = LocalDay.calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func minutes(for date: Date, calendar: Calendar = LocalDay.calendar) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    static func date(for minutes: Int, on dayKey: String, calendar: Calendar = LocalDay.calendar) -> Date? {
        guard let day = date(from: dayKey, calendar: calendar) else { return nil }
        return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)
    }

    static func timeText(for minutes: Int) -> String {
        guard let date = date(for: minutes, on: key(for: Date())) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func dateText(
        for key: String,
        style: Date.FormatStyle.DateStyle = .abbreviated
    ) -> String {
        guard let date = date(from: key) else { return key }
        return date.formatted(date: style, time: .omitted)
    }
}
