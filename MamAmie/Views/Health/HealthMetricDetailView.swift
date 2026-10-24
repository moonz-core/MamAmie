import SwiftUI

public struct HealthMetricDetailView: View {
    public let metric: HealthMetricType
    public let latestReading: HealthReading?
    @ObservedObject public var viewModel: ConnectedHealthViewModel

    @State private var selectedScope: TimeScope = .week
    @State private var trendPoints: [HealthTrendPoint] = []
    @State private var isLoadingTrend = false
    @State private var trendRequestID = UUID()

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
                latestReadingHeader

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

                HealthTrendChartView(
                    metric: metric,
                    points: trendPoints,
                    scope: selectedScope,
                    isLoading: isLoadingTrend
                )

                PregnancyComparisonCard(
                    metric: metric,
                    values: trendPoints.map(\.value),
                    profile: viewModel.profile
                )

                HealthMetricStatsCardView(metric: metric, points: trendPoints)
                maternalContextCard
                deviceProvenanceCard
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var maternalContextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Maternal context in pregnancy", systemImage: "info.circle.fill")
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var deviceProvenanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Device compatibility & accuracy")
                .font(.headline)

            Text(metric.deviceCompatibilityNotice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color("AccentColor"))

                Text("Data is fetched securely via Apple HealthKit with read-only local device permissions.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func loadTrend(for scope: TimeScope) async {
        let requestID = UUID()
        trendRequestID = requestID
        isLoadingTrend = true

        let points = await viewModel.fetchTrends(for: metric, scope: scope)
        guard !Task.isCancelled, requestID == trendRequestID else { return }

        trendPoints = points.sorted { $0.date < $1.date }
        isLoadingTrend = false
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
