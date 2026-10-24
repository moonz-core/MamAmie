import SwiftUI
import Charts

public struct HealthMetricDetailView: View {
    public let metric: HealthMetricType
    public let latestReading: HealthReading?
    @ObservedObject public var viewModel: ConnectedHealthViewModel

    @State private var selectedScope: TimeScope = .week
    @State private var trendPoints: [HealthTrendPoint] = []
    @State private var isLoadingTrend: Bool = false

    public init(
        metric: HealthMetricType,
        latestReading: HealthReading?,
        viewModel: ConnectedHealthViewModel
    ) {
        self.metric = metric
        self.latestReading = latestReading
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Latest Reading Card
                latestReadingHeader

                // Trend Scope Selector
                Picker("Time Period", selection: $selectedScope) {
                    ForEach(TimeScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedScope) { newScope in
                    Task {
                        await loadTrend(for: newScope)
                    }
                }

                // Interactive Chart
                chartCard

                // Statistical Baseline Card
                statsSummaryCard

                // Maternal Health Context
                maternalContextCard

                // Device and Provenance Information
                deviceProvenanceCard

                // Medical Safety Reminder
                MedicalSafetyBannerView()
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTrend(for: selectedScope)
        }
    }

    private var latestReadingHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: metric.iconName)
                    .font(.title2)
                    .foregroundStyle(metric.iconTintColor)
                    .frame(width: 44, height: 44)
                    .background(metric.iconTintColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest Recorded")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let reading = latestReading {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(reading.formattedPrimaryValue)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(reading.unit)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No data")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            if let reading = latestReading {
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
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(metric.shortTitle) Trends (\(selectedScope.rawValue))")
                        .font(.headline)

                    if let first = trendPoints.first?.date, let last = trendPoints.last?.date {
                        Text(formattedDateRange(from: first, to: last))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isLoadingTrend {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if trendPoints.isEmpty && !isLoadingTrend {
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
            } else {
                nativeChart
                    .frame(height: 220)
                    .padding(.vertical, 8)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var nativeChart: some View {
        Chart {
            ForEach(trendPoints) { pt in
                if metric == .activity || metric == .sleep {
                    BarMark(
                        x: .value("Date", pt.date, unit: selectedScope == .day ? .hour : .day),
                        y: .value("Value", pt.value)
                    )
                    .foregroundStyle(metric.iconTintColor.gradient)
                    .cornerRadius(6)
                } else {
                    AreaMark(
                        x: .value("Date", pt.date),
                        y: .value("Value", pt.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [metric.iconTintColor.opacity(0.3), metric.iconTintColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", pt.date),
                        y: .value("Value", pt.value)
                    )
                    .foregroundStyle(metric.iconTintColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Date", pt.date),
                        y: .value("Value", pt.value)
                    )
                    .foregroundStyle(metric.iconTintColor)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            switch selectedScope {
            case .day:
                AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                }
            case .week:
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            case .month:
                AxisMarks(values: .stride(by: .day, count: 6)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
    }

    private func formattedDateRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        switch selectedScope {
        case .day:
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: end)
        case .week:
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "MMM d, yyyy"
            let endStr = formatter.string(from: end)
            return "\(startStr) – \(endStr)"
        case .month:
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "MMM d, yyyy"
            let endStr = formatter.string(from: end)
            return "\(startStr) – \(endStr)"
        }
    }

    private var statsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recorded Period Statistics")
                .font(.headline)

            let values = trendPoints.map(\.value)
            if !values.isEmpty {
                let avg = values.reduce(0, +) / Double(values.count)
                let minVal = values.min() ?? 0
                let maxVal = values.max() ?? 0

                HStack(spacing: 12) {
                    StatBox(label: "Average", value: formatStat(avg), unit: metric.defaultUnit)
                    StatBox(label: "Minimum", value: formatStat(minVal), unit: metric.defaultUnit)
                    StatBox(label: "Maximum", value: formatStat(maxVal), unit: metric.defaultUnit)
                }
            } else {
                Text("Statistical baseline calculations require at least 3 historical readings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var maternalContextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Maternal Context in Pregnancy", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                Text(viewModel.profile.formattedStageSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(metric.maternalContextDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color("AccentColor").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var deviceProvenanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device Compatibility & Accuracy")
                .font(.headline)

            Text(metric.deviceCompatibilityNotice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color("AccentColor"))

                Text("Data is fetched securely via Apple HealthKit with strictly read-only local device permissions.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func loadTrend(for scope: TimeScope) async {
        isLoadingTrend = true
        let points = await viewModel.fetchTrends(for: metric, scope: scope)
        self.trendPoints = points
        isLoadingTrend = false
    }

    private func formatStat(_ value: Double) -> String {
        switch metric {
        case .bloodOxygen:
            return String(format: "%.0f%%", value)
        case .sleep:
            return String(format: "%.1fh", value)
        case .activity:
            return "\(Int(value))"
        case .wristTemperature:
            return String(format: "%.1f°", value)
        default:
            return "\(Int(round(value)))"
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct HealthMetricDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HealthMetricDetailView(
                metric: .heartRate,
                latestReading: HealthReading(
                    metricType: .heartRate,
                    value: 78,
                    unit: "BPM",
                    date: Date(),
                    sourceName: "Apple Watch (Demo)",
                    isResting: true,
                    isSyntheticDemoData: true
                ),
                viewModel: ConnectedHealthViewModel(mockService: MockHealthDataProvider())
            )
        }
    }
}

