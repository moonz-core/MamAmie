import Foundation
import HealthKit
import Combine

struct WatchHeartRatePoint: Identifiable {
    var id = UUID()
    var date: Date
    var beatsPerMinute: Double
}

@MainActor
final class WatchHeartRateService: ObservableObject {
    enum State: Equatable {
        case notRequested
        case loading
        case available
        case noData
        case unavailable
        case error
    }

    @Published private(set) var state: State = .notRequested
    @Published private(set) var latestBPM: Double?
    @Published private(set) var latestDate: Date?
    @Published private(set) var trend: [WatchHeartRatePoint] = []

    private let healthStore: HKHealthStore?
    private let authorizationKey = "mamamie.watch.heart-rate-requested"

    init(healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil) {
        self.healthStore = healthStore
        if healthStore == nil {
            state = .unavailable
        } else if UserDefaults.standard.bool(forKey: authorizationKey) {
            state = .noData
        }
    }

    func requestAccessAndRefresh() async {
        guard let healthStore,
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            state = .unavailable
            return
        }
        state = .loading
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: nil, read: Set<HKObjectType>([heartRate])) { _, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
            UserDefaults.standard.set(true, forKey: authorizationKey)
            await refresh()
        } catch {
            state = .error
        }
    }

    func refresh() async {
        guard healthStore != nil,
              let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            state = .unavailable
            return
        }
        state = .loading
        do {
            let samples = try await query(type: type, limit: 60, since: Calendar.current.date(byAdding: .hour, value: -24, to: Date()))
            guard let mostRecent = samples.last else {
                latestBPM = nil
                latestDate = nil
                trend = []
                state = .noData
                return
            }
            let unit = HKUnit.count().unitDivided(by: .minute())
            latestBPM = mostRecent.quantity.doubleValue(for: unit)
            latestDate = mostRecent.endDate
            trend = samples.map {
                WatchHeartRatePoint(date: $0.endDate, beatsPerMinute: $0.quantity.doubleValue(for: unit))
            }
            state = .available
        } catch {
            state = .error
        }
    }

    private func query(type: HKQuantityType, limit: Int, since: Date?) async throws -> [HKQuantitySample] {
        guard let healthStore else { return [] }
        let predicate = since.map { HKQuery.predicateForSamples(withStart: $0, end: Date(), options: .strictStartDate) }
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples?.compactMap { $0 as? HKQuantitySample } ?? []) }
            }
            healthStore.execute(query)
        }
    }
}
