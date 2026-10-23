import Foundation
import HealthKit

public protocol HealthKitServiceProtocol: AnyObject {
    var isHealthKitSupported: Bool { get }
    func requestAuthorization() async throws -> Bool
    func fetchLatestReading(for metric: HealthMetricType) async throws -> HealthReading?
    func fetchRestingHeartRate() async throws -> HealthReading?
    func fetchTrends(for metric: HealthMetricType, scope: TimeScope) async throws -> [HealthTrendPoint]
}
