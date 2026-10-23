import Foundation
import SwiftUI
import HealthKit

public enum HealthKitConnectionState: Equatable {
    case notConfigured
    case connecting
    case connected
    case restricted
    case unsupported
    case demoMode
}

@MainActor
public final class ConnectedHealthViewModel: ObservableObject {
    @Published public var connectionState: HealthKitConnectionState = .notConfigured
    @Published public var isLoading: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var readings: [HealthMetricType: HealthReading] = [:]
    @Published public var restingHeartRate: HealthReading?
    @Published public var trends: [HealthMetricType: [HealthTrendPoint]] = [:]
    @Published public var metricStatus: [HealthMetricType: MeasurementAvailabilityStatus] = [:]
    @Published public var summary: PersonalHealthSummary?
    @Published public var profile: MaternalHealthProfile = MaternalHealthProfile()
    @Published public var lastSyncDate: Date?
    @Published public var isDemoMode: Bool = false
    @Published public var activeErrorMessage: String?
    @Published public var showPermissionExplainer: Bool = false
    @Published public var showSettingsSheet: Bool = false

    private let realService: HealthKitServiceProtocol
    private let mockService: HealthKitServiceProtocol

    private var activeService: HealthKitServiceProtocol {
        if isDemoMode || !realService.isHealthKitSupported {
            return mockService
        }
        return realService
    }

    public init(
        healthService: HealthKitServiceProtocol = HealthKitService(),
        mockService: HealthKitServiceProtocol = MockHealthDataProvider()
    ) {
        self.realService = healthService
        self.mockService = mockService
        evaluateInitialState()
    }

    public var isHealthKitSupported: Bool {
        realService.isHealthKitSupported
    }

    private func evaluateInitialState() {
        if !realService.isHealthKitSupported {
            connectionState = .unsupported
        } else {
            // Default ready to connect
            connectionState = .notConfigured
        }
    }

    public func connectToAppleHealth() async {
        guard realService.isHealthKitSupported else {
            connectionState = .unsupported
            return
        }

        connectionState = .connecting
        isLoading = true

        do {
            let success = try await realService.requestAuthorization()
            if success {
                connectionState = .connected
                await loadAllHealthData()
            } else {
                connectionState = .restricted
            }
        } catch {
            connectionState = .restricted
            activeErrorMessage = "Apple Health authorization was not completed. You can update this anytime in Settings."
        }

        isLoading = false
    }

    public func loadAllHealthData() async {
        isLoading = true

        let service = activeService
        var newReadings: [HealthMetricType: HealthReading] = [:]
        var newStatus: [HealthMetricType: MeasurementAvailabilityStatus] = [:]

        // Fetch resting HR first
        do {
            restingHeartRate = try await service.fetchRestingHeartRate()
        } catch {
            restingHeartRate = nil
        }

        // Fetch latest reading for all 7 metrics in parallel
        await withTaskGroup(of: (HealthMetricType, HealthReading?, MeasurementAvailabilityStatus).self) { group in
            for metric in HealthMetricType.allCases {
                group.addTask {
                    do {
                        let reading = try await service.fetchLatestReading(for: metric)
                        if let reading = reading {
                            return (metric, reading, .available)
                        } else {
                            return (metric, nil, .noDataRecorded)
                        }
                    } catch {
                        return (metric, nil, .error(error.localizedDescription))
                    }
                }
            }

            for await (metric, reading, status) in group {
                newStatus[metric] = status
                if let reading = reading {
                    newReadings[metric] = reading
                }
            }
        }

        self.readings = newReadings
        self.metricStatus = newStatus

        // Fetch 7-day trends for summary metrics
        await loadInitialTrends()

        // Generate deterministic non-diagnostic summary
        self.summary = PersonalHealthSummary.deterministicSummary(
            readings: newReadings,
            trends: self.trends,
            profile: self.profile
        )

        self.lastSyncDate = Date()
        self.isLoading = false
    }

    public func refresh() async {
        isRefreshing = true
        await loadAllHealthData()
        isRefreshing = false
    }

    public func loadInitialTrends() async {
        let service = activeService
        var newTrends: [HealthMetricType: [HealthTrendPoint]] = [:]

        for metric in [HealthMetricType.heartRate, .sleep, .activity] {
            do {
                let pts = try await service.fetchTrends(for: metric, scope: .week)
                newTrends[metric] = pts
            } catch {
                newTrends[metric] = []
            }
        }
        self.trends = newTrends
    }

    public func fetchTrends(for metric: HealthMetricType, scope: TimeScope) async -> [HealthTrendPoint] {
        do {
            return try await activeService.fetchTrends(for: metric, scope: scope)
        } catch {
            return []
        }
    }

    public func enableDemoMode() async {
        isDemoMode = true
        connectionState = .demoMode
        await loadAllHealthData()
    }

    public func disableDemoMode() async {
        isDemoMode = false
        evaluateInitialState()
        readings.removeAll()
        trends.removeAll()
        summary = nil
        lastSyncDate = nil
    }
}
