import Foundation

public final class MockHealthDataProvider: HealthKitServiceProtocol {
    public var isHealthKitSupported: Bool { true }

    public init() {}

    public func requestAuthorization() async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return true
    }

    public func fetchLatestReading(for metric: HealthMetricType) async throws -> HealthReading? {
        let now = Date()
        switch metric {
        case .heartRate:
            return HealthReading(
                metricType: .heartRate,
                value: 78,
                unit: "BPM",
                date: now.addingTimeInterval(-15 * 60),
                sourceName: "Apple Watch (Demo)",
                isResting: true,
                isSyntheticDemoData: true
            )
        case .bloodOxygen:
            return HealthReading(
                metricType: .bloodOxygen,
                value: 98,
                unit: "%",
                date: now.addingTimeInterval(-2 * 3600),
                sourceName: "Apple Watch Series 9 (Demo)",
                isSyntheticDemoData: true
            )
        case .bloodPressure:
            return HealthReading(
                metricType: .bloodPressure,
                value: 114,
                secondaryValue: 74,
                unit: "mmHg",
                date: now.addingTimeInterval(-4 * 3600),
                sourceName: "Wireless BP Monitor (Demo)",
                isSyntheticDemoData: true
            )
        case .sleep:
            return HealthReading(
                metricType: .sleep,
                value: 7.6,
                unit: "hrs",
                date: now.addingTimeInterval(-6 * 3600),
                sourceName: "Apple Watch (Demo)",
                isSyntheticDemoData: true
            )
        case .activity:
            return HealthReading(
                metricType: .activity,
                value: 6420,
                unit: "steps",
                date: now.addingTimeInterval(-10 * 60),
                sourceName: "Apple Watch & iPhone (Demo)",
                isSyntheticDemoData: true
            )
        case .heartRateVariability:
            return HealthReading(
                metricType: .heartRateVariability,
                value: 48,
                unit: "ms",
                date: now.addingTimeInterval(-3 * 3600),
                sourceName: "Apple Watch (Demo)",
                isSyntheticDemoData: true
            )
        case .wristTemperature:
            return HealthReading(
                metricType: .wristTemperature,
                value: 36.5,
                unit: "°C",
                date: now.addingTimeInterval(-7 * 3600),
                sourceName: "Apple Watch Series 9 (Demo)",
                isSyntheticDemoData: true
            )
        }
    }

    public func fetchRestingHeartRate() async throws -> HealthReading? {
        return HealthReading(
            metricType: .heartRate,
            value: 74,
            unit: "BPM",
            date: Date().addingTimeInterval(-3600),
            sourceName: "Apple Watch (Demo)",
            isResting: true,
            isSyntheticDemoData: true
        )
    }

    public func fetchTrends(for metric: HealthMetricType, scope: TimeScope) async throws -> [HealthTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var points: [HealthTrendPoint] = []

        let count: Int
        let stepInterval: Calendar.Component
        switch scope {
        case .day:
            count = 12
            stepInterval = .hour
        case .week:
            count = 7
            stepInterval = .day
        case .month:
            count = 30
            stepInterval = .day
        }

        let baseVal: Double
        let variance: Double
        switch metric {
        case .heartRate: baseVal = 76; variance = 8
        case .bloodOxygen: baseVal = 98; variance = 1.2
        case .bloodPressure: baseVal = 114; variance = 6
        case .sleep: baseVal = 7.5; variance = 1.2
        case .activity: baseVal = 6200; variance = 1800
        case .heartRateVariability: baseVal = 50; variance = 12
        case .wristTemperature: baseVal = 36.5; variance = 0.3
        }

        let labelFormatter = DateFormatter()
        switch scope {
        case .day:
            labelFormatter.dateFormat = "h a"
        case .week:
            labelFormatter.dateFormat = "EEE"
        case .month:
            labelFormatter.dateFormat = "MMM d"
        }

        let startOfToday = calendar.startOfDay(for: now)

        for index in 0..<count {
            let offset = count - 1 - index
            let pointDate: Date
            if stepInterval == .hour {
                // Spaced 2 hours apart across today: 00:00, 02:00, ..., 22:00
                pointDate = calendar.date(byAdding: .hour, value: index * 2, to: startOfToday) ?? now
            } else {
                pointDate = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? now
            }

            let noise = sin(Double(index) * 0.9) * variance
            let val = max(1.0, baseVal + noise)
            let secVal: Double? = metric == .bloodPressure ? max(50.0, 74 + (noise * 0.6)) : nil

            points.append(
                HealthTrendPoint(
                    date: pointDate,
                    value: val,
                    secondaryValue: secVal,
                    minValue: val - (variance * 0.4),
                    maxValue: val + (variance * 0.4),
                    label: labelFormatter.string(from: pointDate)
                )
            )
        }

        return points
    }
}
