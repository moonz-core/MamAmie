import SwiftUI

struct TrendReadingsListView: View {
    let points: [HealthTrendPoint]
    let metric: HealthMetricType
    let scope: TimeScope

    private var visiblePoints: [HealthTrendPoint] {
        Array(points.suffix(scope == .month ? 7 : points.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recorded points")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Local time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if visiblePoints.isEmpty {
                Text("No timestamped readings in this period.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visiblePoints) { point in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(metric.iconTintColor)
                            .frame(width: 7, height: 7)

                        Text(HealthTrendFormatting.pointDateTime(for: point.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 8)

                        Text(metric.formattedValue(point.value))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(metric.defaultUnit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        HealthTrendFormatting.accessiblePointLabel(
                            date: point.date,
                            value: metric.formattedValue(point.value),
                            metric: metric
                        )
                    )
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
