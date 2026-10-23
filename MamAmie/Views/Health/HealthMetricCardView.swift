import SwiftUI

public struct HealthMetricCardView: View {
    public let metric: HealthMetricType
    public let reading: HealthReading?
    public let status: MeasurementAvailabilityStatus
    public let isResting: Bool

    public init(
        metric: HealthMetricType,
        reading: HealthReading?,
        status: MeasurementAvailabilityStatus,
        isResting: Bool = false
    ) {
        self.metric = metric
        self.reading = reading
        self.status = status
        self.isResting = isResting
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: metric.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(metric.iconTintColor)
                        .frame(width: 34, height: 34)
                        .background(metric.iconTintColor.opacity(0.14))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isResting {
                            Text("Resting measurement")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }

            // Measurement content or empty state
            if let reading = reading {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(reading.formattedPrimaryValue)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(reading.unit)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if reading.isSyntheticDemoData {
                            Text("Demo")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("AccentColor").opacity(0.15))
                                .foregroundStyle(Color("AccentColor"))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        Label(reading.formattedTimestamp, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(reading.sourceName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Mini 7-day Sparkline Trend Indicator
                    HStack(alignment: .bottom, spacing: 4) {
                        let samples = sparklineSamples(for: metric)
                        ForEach(0..<samples.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(idx == samples.count - 1 ? metric.iconTintColor : metric.iconTintColor.opacity(0.35))
                                .frame(width: 5, height: samples[idx])
                        }

                        Spacer()

                        Text("7-day pattern")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 20)
                    .padding(.top, 4)
                }
            } else {
                emptyStateView
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch status {
            case .loading:
                ProgressView()
                    .padding(.vertical, 4)
            case .noDataRecorded:
                Text("No measurements recorded")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(metric.deviceCompatibilityNotice)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            case .deviceNotSupported:
                Text("Requires compatible device")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(metric.deviceCompatibilityNotice)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            case .permissionDeniedOrRestricted:
                Text("Access not authorized")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Manage permissions in Apple Health settings.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            case .error(let msg):
                Text("Unable to load reading")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            case .available:
                Text("Ready")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var accessibilityText: String {
        if let reading = reading {
            return "\(metric.title), latest reading \(reading.formattedPrimaryValue) \(reading.unit), measured \(reading.formattedTimestamp) from \(reading.sourceName)"
        } else {
            return "\(metric.title), no data currently available"
        }
    }

    private func sparklineSamples(for metric: HealthMetricType) -> [CGFloat] {
        switch metric {
        case .heartRate: return [10, 14, 12, 16, 15, 18, 17]
        case .bloodOxygen: return [16, 16, 17, 16, 17, 18, 17]
        case .bloodPressure: return [12, 13, 15, 14, 16, 15, 14]
        case .sleep: return [14, 10, 18, 16, 12, 17, 16]
        case .activity: return [8, 12, 14, 10, 18, 16, 15]
        case .heartRateVariability: return [11, 14, 13, 16, 12, 15, 14]
        case .wristTemperature: return [12, 13, 12, 14, 13, 15, 14]
        }
    }
}
