import Foundation

/// A non-diagnostic comparison reference for the health detail screen.
/// These broad product references are intentionally presented as context, not targets,
/// diagnosis, or treatment guidance. They should be replaced with reviewed clinical
/// content before being used as a medical recommendation.
public struct PregnancyReference: Identifiable, Equatable {
    public let id: String
    public let metric: HealthMetricType
    public let average: Double
    public let range: ClosedRange<Double>
    public let unit: String
    public let label: String
    public let note: String

    public init(
        metric: HealthMetricType,
        average: Double,
        range: ClosedRange<Double>,
        unit: String,
        label: String,
        note: String
    ) {
        self.id = metric.id
        self.metric = metric
        self.average = average
        self.range = range
        self.unit = unit
        self.label = label
        self.note = note
    }

    public func relation(for value: Double) -> ReferenceRelation {
        if value < range.lowerBound { return .below }
        if value > range.upperBound { return .above }
        return .within
    }

    public enum ReferenceRelation: Equatable {
        case below
        case within
        case above

        public var title: String {
            switch self {
            case .below: return "Below this reference"
            case .within: return "Within this reference"
            case .above: return "Above this reference"
            }
        }
    }
}

/// Provides broad, non-diagnostic context for the graph comparison card.
/// There is no universal pregnancy target for every wearable metric, so the UI
/// explicitly labels these values as general context and retains the metric note.
public enum PregnancyReferenceLibrary {
    public static func reference(for metric: HealthMetricType) -> PregnancyReference {
        switch metric {
        case .heartRate:
            return PregnancyReference(
                metric: metric,
                average: 80,
                range: 70...90,
                unit: "BPM",
                label: "General resting heart-rate context",
                note: "Individual baselines vary widely. Resting readings are more meaningful than an all-day heart-rate average."
            )
        case .bloodOxygen:
            return PregnancyReference(
                metric: metric,
                average: 97,
                range: 95...100,
                unit: "%",
                label: "General oxygen-saturation context",
                note: "This is broad wellness context, not a clinical threshold or diagnosis."
            )
        case .bloodPressure:
            return PregnancyReference(
                metric: metric,
                average: 110,
                range: 90...120,
                unit: "mmHg systolic",
                label: "General systolic context",
                note: "A validated cuff and your care team's guidance are more appropriate for blood-pressure decisions."
            )
        case .sleep:
            return PregnancyReference(
                metric: metric,
                average: 8,
                range: 7...9,
                unit: "hrs",
                label: "General sleep-duration context",
                note: "Sleep needs and interruptions differ throughout pregnancy; there is no universal pregnancy target."
            )
        case .activity:
            return PregnancyReference(
                metric: metric,
                average: 6_000,
                range: 4_000...8_000,
                unit: "steps",
                label: "General daily-movement context",
                note: "There is no universal pregnancy step target. Adjust movement to your energy and clinician guidance."
            )
        case .heartRateVariability:
            return PregnancyReference(
                metric: metric,
                average: 45,
                range: 30...60,
                unit: "ms",
                label: "General HRV context",
                note: "HRV fluctuates with sleep, stress, device fit, and pregnancy; it is not an isolated clinical measure."
            )
        case .wristTemperature:
            return PregnancyReference(
                metric: metric,
                average: 36.5,
                range: 36.2...36.8,
                unit: "°C",
                label: "General overnight-temperature context",
                note: "Wrist temperature is not core body temperature and should not be used to assess fever."
            )
        }
    }
}
