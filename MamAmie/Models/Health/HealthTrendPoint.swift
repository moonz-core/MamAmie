import Foundation

public enum TimeScope: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    public var id: String { rawValue }

    public var rangeInDays: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

public enum TrendDirection: Equatable {
    case increasing(delta: Double)
    case decreasing(delta: Double)
    case stable
    case insufficientData

    public var iconName: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .insufficientData: return "ellipsis"
        }
    }

    public var description: String {
        switch self {
        case .increasing(let delta):
            return String(format: "+%.1f change", delta)
        case .decreasing(let delta):
            return String(format: "-%.1f change", abs(delta))
        case .stable:
            return "Stable"
        case .insufficientData:
            return "Trend pending data"
        }
    }
}

public struct HealthTrendPoint: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let value: Double
    public let secondaryValue: Double?
    public let minValue: Double?
    public let maxValue: Double?
    public let label: String

    public init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        secondaryValue: Double? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        label: String
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.secondaryValue = secondaryValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.label = label
    }
}
