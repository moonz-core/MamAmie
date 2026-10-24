import Foundation

/// Centralizes the date presentation used by trend charts and their supporting values.
/// Chart axes use the point's Date instead of a preformatted String so values remain
/// correctly ordered and retain the user's local timezone.
public enum HealthTrendFormatting {
    public static func axisLabel(for date: Date, scope: TimeScope) -> String {
        switch scope {
        case .day:
            return date.formatted(date: .omitted, time: .shortened)
        case .week:
            return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .month:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    public static func pointDateTime(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    public static func pointTime(for date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    public static func accessiblePointLabel(
        date: Date,
        value: String,
        metric: HealthMetricType
    ) -> String {
        "\(metric.title), \(value), recorded \(pointDateTime(for: date))"
    }
}
