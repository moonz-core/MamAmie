import Charts
import SwiftUI

struct HealthTrendChartView: View {
    let metric: HealthMetricType
    let points: [HealthTrendPoint]
    let scope: TimeScope
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(metric.shortTitle) trends")
                    .font(.headline)

                Spacer()

                Text(scope.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if points.isEmpty && !isLoading {
                emptyState
            } else {
                chart
                    .frame(height: 220)
                    .padding(.vertical, 8)

                TrendReadingsListView(points: points, metric: metric, scope: scope)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                if metric == .activity || metric == .sleep {
                    BarMark(
                        x: .value("Date and time", point.date),
                        y: .value(metric.defaultUnit, point.value)
                    )
                    .foregroundStyle(metric.iconTintColor.gradient)
                    .cornerRadius(6)
                } else {
                    AreaMark(
                        x: .value("Date and time", point.date),
                        y: .value(metric.defaultUnit, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [metric.iconTintColor.opacity(0.3), metric.iconTintColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date and time", point.date),
                        y: .value(metric.defaultUnit, point.value)
                    )
                    .foregroundStyle(metric.iconTintColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Date and time", point.date),
                        y: .value(metric.defaultUnit, point.value)
                    )
                    .foregroundStyle(metric.iconTintColor)
                }
            }
        }
        .chartXScale(domain: chartDomain)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: scope.axisLabelCount)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.15))
                AxisTick()
                    .foregroundStyle(Color.secondary.opacity(0.35))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(HealthTrendFormatting.axisLabel(for: date, scope: scope))
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(metric.title) trend chart. Dates and times use your local timezone.")
    }

    private var chartDomain: ClosedRange<Date> {
        guard let first = points.map(\.date).min(), let last = points.map(\.date).max() else {
            let now = Date()
            return now.addingTimeInterval(-86_400)...now
        }

        if first == last {
            let padding: TimeInterval = scope == .day ? 3_600 : 86_400
            return first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
        }

        let padding: TimeInterval = scope == .day ? 3_600 : 86_400
        return first.addingTimeInterval(-padding)...last.addingTimeInterval(padding)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
                .padding(.top, 16)

            Text("Insufficient trend data")
                .font(.subheadline.weight(.semibold))

            Text("Historical patterns will appear here once consistent readings are synced from Apple Health.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}
