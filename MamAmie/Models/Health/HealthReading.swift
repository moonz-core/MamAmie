import Foundation

public enum MeasurementAvailabilityStatus: Equatable {
    case available
    case noDataRecorded
    case permissionDeniedOrRestricted
    case deviceNotSupported
    case loading
    case error(String)
}

public struct HealthReading: Identifiable, Equatable {
    public let id: UUID
    public let metricType: HealthMetricType
    public let value: Double
    public let secondaryValue: Double?
    public let unit: String
    public let date: Date
    public let sourceName: String
    public let isResting: Bool
    public let isSyntheticDemoData: Bool

    public init(
        id: UUID = UUID(),
        metricType: HealthMetricType,
        value: Double,
        secondaryValue: Double? = nil,
        unit: String,
        date: Date,
        sourceName: String = "Apple Health",
        isResting: Bool = false,
        isSyntheticDemoData: Bool = false
    ) {
        self.id = id
        self.metricType = metricType
        self.value = value
        self.secondaryValue = secondaryValue
        self.unit = unit
        self.date = date
        self.sourceName = sourceName
        self.isResting = isResting
        self.isSyntheticDemoData = isSyntheticDemoData
    }

    public var formattedPrimaryValue: String {
        switch metricType {
        case .heartRate:
            return "\(Int(round(value)))"
        case .bloodOxygen:
            let pct = value <= 1.0 ? value * 100.0 : value
            return String(format: "%.0f%%", pct)
        case .bloodPressure:
            if let secondary = secondaryValue {
                return "\(Int(round(value)))/\(Int(round(secondary)))"
            }
            return "\(Int(round(value)))"
        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        case .activity:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
        case .heartRateVariability:
            return "\(Int(round(value)))"
        case .wristTemperature:
            return String(format: "%.1f°", value)
        }
    }

    public var formattedTimestamp: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, " + formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday, " + formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    public var relativeTimeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
