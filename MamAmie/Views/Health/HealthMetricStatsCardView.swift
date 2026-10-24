import SwiftUI

struct HealthMetricStatsCardView: View {
    let metric: HealthMetricType
    let points: [HealthTrendPoint]

    private var values: [Double] {
        points.map(\.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recorded period statistics")
                .font(.headline)

            if !values.isEmpty {
                HStack(spacing: 12) {
                    StatBox(label: "Average", value: metric.formattedValue(average), unit: metric.defaultUnit)
                    StatBox(label: "Minimum", value: metric.formattedValue(values.min() ?? 0), unit: metric.defaultUnit)
                    StatBox(label: "Maximum", value: metric.formattedValue(values.max() ?? 0), unit: metric.defaultUnit)
                }
            } else {
                Text("Statistical baseline calculations require historical readings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var average: Double {
        values.reduce(0, +) / Double(max(values.count, 1))
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
