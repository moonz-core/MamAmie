import Foundation
import HealthKit

public final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore: HKHealthStore?

    public init(healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil) {
        self.healthStore = healthStore
    }

    public var isHealthKitSupported: Bool {
        return HKHealthStore.isHealthDataAvailable() && healthStore != nil
    }

    private var allReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .restingHeartRate,
            .oxygenSaturation,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .stepCount,
            .heartRateVariabilitySDNN
        ]

        for id in quantityIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }

        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        if #available(iOS 16.0, *) {
            if let wristTemp = HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature) {
                types.insert(wristTemp)
            }
        }
        if let bodyTemp = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }

        return types
    }

    public func requestAuthorization() async throws -> Bool {
        guard let healthStore = healthStore else {
            return false
        }

        let types = allReadTypes
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    public func fetchLatestReading(for metric: HealthMetricType) async throws -> HealthReading? {
        guard let healthStore = healthStore else { return nil }

        switch metric {
        case .heartRate:
            guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
            return try await fetchMostRecentQuantity(type: type, unit: HKUnit(from: "count/min"), metric: .heartRate)

        case .bloodOxygen:
            guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return nil }
            return try await fetchMostRecentQuantity(type: type, unit: HKUnit.percent(), metric: .bloodOxygen)

        case .bloodPressure:
            return try await fetchMostRecentBloodPressure()

        case .sleep:
            return try await fetchMostRecentSleep()

        case .activity:
            return try await fetchTodaySteps()

        case .heartRateVariability:
            guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
            return try await fetchMostRecentQuantity(type: type, unit: HKUnit.secondUnit(with: .milli), metric: .heartRateVariability)

        case .wristTemperature:
            if #available(iOS 16.0, *) {
                if let type = HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature) {
                    if let reading = try await fetchMostRecentQuantity(type: type, unit: HKUnit.degreeCelsius(), metric: .wristTemperature) {
                        return reading
                    }
                }
            }
            if let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) {
                return try await fetchMostRecentQuantity(type: type, unit: HKUnit.degreeCelsius(), metric: .wristTemperature)
            }
            return nil
        }
    }

    public func fetchRestingHeartRate() async throws -> HealthReading? {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }
        return try await fetchMostRecentQuantity(type: type, unit: HKUnit(from: "count/min"), metric: .heartRate, isResting: true)
    }

    private func fetchMostRecentQuantity(
        type: HKQuantityType,
        unit: HKUnit,
        metric: HealthMetricType,
        isResting: Bool = false
    ) async throws -> HealthReading? {
        guard let healthStore = healthStore else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                let sourceName = sample.sourceRevision.source.name
                let reading = HealthReading(
                    metricType: metric,
                    value: value,
                    unit: metric.defaultUnit,
                    date: sample.endDate,
                    sourceName: sourceName,
                    isResting: isResting,
                    isSyntheticDemoData: false
                )
                continuation.resume(returning: reading)
            }
            healthStore.execute(query)
        }
    }

    private func fetchMostRecentBloodPressure() async throws -> HealthReading? {
        guard let healthStore = healthStore,
              let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let unit = HKUnit.millimeterOfMercury()

        let systolic = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Error>) in
            let query = HKSampleQuery(sampleType: systolicType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            healthStore.execute(query)
        }

        guard let systolicSample = systolic else { return nil }

        // Find corresponding diastolic sample close to the same time
        let timeWindow = 60.0
        let predicate = HKQuery.predicateForSamples(
            withStart: systolicSample.startDate.addingTimeInterval(-timeWindow),
            end: systolicSample.endDate.addingTimeInterval(timeWindow),
            options: []
        )

        let diastolic = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Error>) in
            let query = HKSampleQuery(sampleType: diastolicType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            healthStore.execute(query)
        }

        let sysVal = systolicSample.quantity.doubleValue(for: unit)
        let diaVal = diastolic?.quantity.doubleValue(for: unit)

        return HealthReading(
            metricType: .bloodPressure,
            value: sysVal,
            secondaryValue: diaVal,
            unit: "mmHg",
            date: systolicSample.endDate,
            sourceName: systolicSample.sourceRevision.source.name,
            isSyntheticDemoData: false
        )
    }

    private func fetchMostRecentSleep() async throws -> HealthReading? {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -2, to: now) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 50, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Group samples by most recent sleep session (within past 24 hours)
                let recentSamples = categorySamples.filter { sample in
                    sample.endDate.timeIntervalSinceNow > -86400
                }

                var totalAsleepSeconds: TimeInterval = 0
                var latestDate = Date.distantPast
                var source = "Apple Health"

                for sample in recentSamples {
                    // Check if sample represents asleep
                    let isAsleep: Bool
                    if #available(iOS 16.0, *) {
                        isAsleep = (sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
                    } else {
                        isAsleep = (sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue)
                    }

                    if isAsleep {
                        totalAsleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                        if sample.endDate > latestDate {
                            latestDate = sample.endDate
                            source = sample.sourceRevision.source.name
                        }
                    }
                }

                if totalAsleepSeconds > 0 {
                    let hours = totalAsleepSeconds / 3600.0
                    let reading = HealthReading(
                        metricType: .sleep,
                        value: hours,
                        unit: "hrs",
                        date: latestDate,
                        sourceName: source,
                        isSyntheticDemoData: false
                    )
                    continuation.resume(returning: reading)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchTodaySteps() async throws -> HealthReading? {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let steps = sum.doubleValue(for: HKUnit.count())
                let reading = HealthReading(
                    metricType: .activity,
                    value: steps,
                    unit: "steps",
                    date: Date(),
                    sourceName: "iPhone / Apple Watch",
                    isSyntheticDemoData: false
                )
                continuation.resume(returning: reading)
            }
            healthStore.execute(query)
        }
    }

    public func fetchTrends(for metric: HealthMetricType, scope: TimeScope) async throws -> [HealthTrendPoint] {
        guard let healthStore = healthStore else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let days = scope.rangeInDays
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }

        switch metric {
        case .activity:
            guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
            var interval = DateComponents()
            interval.day = 1

            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

            return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: calendar.startOfDay(for: startDate),
                    intervalComponents: interval
                )

                query.initialResultsHandler = { _, collection, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    var points: [HealthTrendPoint] = []
                    let dayFormatter = DateFormatter()
                    switch scope {
                    case .day:
                        dayFormatter.dateFormat = "h a"
                    case .week:
                        dayFormatter.dateFormat = "EEE"
                    case .month:
                        dayFormatter.dateFormat = "MMM d"
                    }

                    collection?.enumerateStatistics(from: startDate, to: now) { stats, _ in
                        if let sum = stats.sumQuantity() {
                            let steps = sum.doubleValue(for: HKUnit.count())
                            let point = HealthTrendPoint(
                                date: stats.startDate,
                                value: steps,
                                label: dayFormatter.string(from: stats.startDate)
                            )
                            points.append(point)
                        }
                    }
                    continuation.resume(returning: points)
                }
                healthStore.execute(query)
            }

        case .heartRate:
            guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
            return try await fetchDiscreteTrend(
                quantityType: hrType,
                unit: HKUnit(from: "count/min"),
                startDate: startDate,
                endDate: now,
                scope: scope
            )

        default:
            // Generic sample fetch for other metrics
            guard let qType = metric.sampleQuantityType else { return [] }
            let unit: HKUnit
            switch metric {
            case .bloodOxygen: unit = HKUnit.percent()
            case .bloodPressure: unit = HKUnit.millimeterOfMercury()
            case .heartRateVariability: unit = HKUnit.secondUnit(with: .milli)
            case .wristTemperature: unit = HKUnit.degreeCelsius()
            default: unit = HKUnit.count()
            }
            return try await fetchDiscreteTrend(
                quantityType: qType,
                unit: unit,
                startDate: startDate,
                endDate: now,
                scope: scope
            )
        }
    }

    private func fetchDiscreteTrend(
        quantityType: HKQuantityType,
        unit: HKUnit,
        startDate: Date,
        endDate: Date,
        scope: TimeScope
    ) async throws -> [HealthTrendPoint] {
        guard let healthStore = healthStore else { return [] }
        let calendar = Calendar.current

        var interval = DateComponents()
        if scope == .day {
            interval.hour = 2
        } else {
            interval.day = 1
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage, .discreteMin, .discreteMax],
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var points: [HealthTrendPoint] = []
                let labelFormatter = DateFormatter()
                switch scope {
                case .day:
                    labelFormatter.dateFormat = "h a"
                case .week:
                    labelFormatter.dateFormat = "EEE"
                case .month:
                    labelFormatter.dateFormat = "MMM d"
                }

                collection?.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    if let avg = stats.averageQuantity() {
                        var val = avg.doubleValue(for: unit)
                        if unit == HKUnit.percent() && val <= 1.0 {
                            val *= 100.0
                        }
                        let minVal = stats.minimumQuantity()?.doubleValue(for: unit)
                        let maxVal = stats.maximumQuantity()?.doubleValue(for: unit)

                        let point = HealthTrendPoint(
                            date: stats.startDate,
                            value: val,
                            minValue: minVal,
                            maxValue: maxVal,
                            label: labelFormatter.string(from: stats.startDate)
                        )
                        points.append(point)
                    }
                }
                continuation.resume(returning: points)
            }
            healthStore.execute(query)
        }
    }
}
