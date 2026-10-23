import SwiftUI

public struct ConnectedHealthDashboardView: View {
    @StateObject private var viewModel = ConnectedHealthViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header section
                    dashboardHeader

                    // Not Connected / Onboarding Banner (if not connected yet)
                    if viewModel.connectionState == .notConfigured || viewModel.connectionState == .restricted {
                        connectPromptCard
                    }

                    // Maternal Stage Context Banner
                    maternalStageBanner

                    // Today's Health Overview Cards (7 categories)
                    todaysHealthOverviewSection

                    // Weekly Wellbeing Summary
                    WeeklyWellbeingSummaryCard(summary: viewModel.summary, profile: viewModel.profile)

                    // Medical Safety & Disclaimer Section
                    MedicalSafetyBannerView()
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Connected Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color("AccentColor"))
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showPermissionExplainer) {
                HealthPermissionSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showSettingsSheet) {
                HealthSourceSettingsSheet(viewModel: viewModel)
            }
            .task {
                // If in demo mode or already authorized, load data
                if viewModel.connectionState == .connected || viewModel.isDemoMode {
                    await viewModel.loadAllHealthData()
                }
            }
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Health, Connected")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color("AccentColor"))

                    Text("Bringing together measurements from Apple Health and compatible wearables to support your maternal journey.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Connection status pill
            HStack(spacing: 8) {
                Circle()
                    .fill(statusIndicatorColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    viewModel.showSettingsSheet = true
                } label: {
                    Text("Manage")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }

    private var connectPromptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 42, height: 42)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Apple Health")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Sync resting heart rate, sleep, steps, and SpO2 from your wearable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.showPermissionExplainer = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Devices")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("AccentColor"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    Task {
                        await viewModel.enableDemoMode()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Preview Demo")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color("AccentColor").opacity(0.12))
                    .foregroundStyle(Color("AccentColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(18)
        .background(Color("AccentColor").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var maternalStageBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.and.child.holdinghands")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 36, height: 36)
                .background(Color("AccentColor").opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.profile.formattedStageSubtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(viewModel.profile.stage.contextDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var todaysHealthOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Health Overview")
                    .font(.title3.bold())

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            VStack(spacing: 12) {
                ForEach(HealthMetricType.allCases) { metric in
                    NavigationLink {
                        HealthMetricDetailView(
                            metric: metric,
                            latestReading: viewModel.readings[metric],
                            viewModel: viewModel
                        )
                    } label: {
                        HealthMetricCardView(
                            metric: metric,
                            reading: viewModel.readings[metric],
                            status: viewModel.metricStatus[metric] ?? .noDataRecorded,
                            isResting: metric == .heartRate && viewModel.restingHeartRate != nil
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusText: String {
        switch viewModel.connectionState {
        case .connected:
            return "Apple Health Connected"
        case .demoMode:
            return "Sample Demonstration Data Active"
        case .connecting:
            return "Connecting..."
        case .restricted:
            return "Permissions Need Review"
        case .unsupported:
            return "HealthKit Unavailable on this Device"
        case .notConfigured:
            return "Ready to Connect"
        }
    }

    private var statusIndicatorColor: Color {
        switch viewModel.connectionState {
        case .connected: return .green
        case .demoMode: return Color("AccentColor")
        case .restricted: return .orange
        case .connecting: return .blue
        case .unsupported: return .gray
        case .notConfigured: return .secondary
        }
    }
}

struct ConnectedHealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedHealthDashboardView()
    }
}

