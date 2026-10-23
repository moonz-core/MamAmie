import Foundation

public struct PersonalHealthSummary: Equatable {
    public let generatedDate: Date
    public let periodTitle: String
    public let restingHeartRateObservation: String
    public let sleepObservation: String
    public let activityObservation: String
    public let overallObservation: String
    public let isSufficientDataAvailable: Bool

    public static let standardMedicalDisclaimer =
        "Wearable device measurements are for personal maternal wellness tracking and personal reference only. They do not monitor fetal heart rate, diagnose preeclampsia or gestational complications, or replace regular prenatal consultations with your obstetrician or midwife. If you experience severe headaches, vision changes, sudden swelling, pain, bleeding, or reduced fetal movement, contact your care team or emergency services immediately."

    public init(
        generatedDate: Date = Date(),
        periodTitle: String = "Past 7 Days",
        restingHeartRateObservation: String,
        sleepObservation: String,
        activityObservation: String,
        overallObservation: String,
        isSufficientDataAvailable: Bool
    ) {
        self.generatedDate = generatedDate
        self.periodTitle = periodTitle
        self.restingHeartRateObservation = restingHeartRateObservation
        self.sleepObservation = sleepObservation
        self.activityObservation = activityObservation
        self.overallObservation = overallObservation
        self.isSufficientDataAvailable = isSufficientDataAvailable
    }

    public static func deterministicSummary(
        readings: [HealthMetricType: HealthReading],
        trends: [HealthMetricType: [HealthTrendPoint]],
        profile: MaternalHealthProfile
    ) -> PersonalHealthSummary {
        var hrNote = "Resting heart rate data is awaiting more recorded days."
        var sleepNote = "Sleep duration data is awaiting more nights of sleep tracking."
        var activityNote = "Activity records are gathering your baseline steps."
        var overallNote = "As you wear your device regularly, MamAmie will display neutral statistical comparisons to your earlier averages."
        var hasData = false

        // 1. Heart rate analysis
        if let hrPoints = trends[.heartRate], hrPoints.count >= 3 {
            hasData = true
            let avg = hrPoints.map(\.value).reduce(0, +) / Double(hrPoints.count)
            let firstHalf = hrPoints.prefix(hrPoints.count / 2).map(\.value)
            let secondHalf = hrPoints.suffix(hrPoints.count / 2).map(\.value)
            let avgFirst = firstHalf.reduce(0, +) / Double(max(1, firstHalf.count))
            let avgSecond = secondHalf.reduce(0, +) / Double(max(1, secondHalf.count))
            let diff = avgSecond - avgFirst

            if abs(diff) < 2.0 {
                hrNote = String(format: "Your recorded heart rate has remained steady this period, averaging %.0f BPM.", avg)
            } else if diff > 0 {
                hrNote = String(format: "Your recorded heart rate averaged %.0f BPM, trending about %.0f BPM higher than your earlier baseline in this period. A gentle rise is common during %@ as blood volume expands.", avg, diff, profile.stage.badgeLabel)
            } else {
                hrNote = String(format: "Your recorded heart rate averaged %.0f BPM, slightly lower by %.0f BPM compared to your initial readings in this window.", avg, abs(diff))
            }
        } else if let latestHR = readings[.heartRate] {
            hrNote = "Latest recorded heart rate was \(latestHR.formattedPrimaryValue) BPM."
            hasData = true
        }

        // 2. Sleep analysis
        if let sleepPoints = trends[.sleep], sleepPoints.count >= 3 {
            hasData = true
            let avg = sleepPoints.map(\.value).reduce(0, +) / Double(sleepPoints.count)
            let hours = Int(avg)
            let mins = Int((avg - Double(hours)) * 60)
            sleepNote = String(format: "Recorded sleep averaged %dh %02dm over the last %d tracked nights. Tracking rest helps you prioritize quiet downtime.", hours, mins, sleepPoints.count)
        } else if let latestSleep = readings[.sleep] {
            sleepNote = "Latest sleep session recorded was \(latestSleep.formattedPrimaryValue)."
            hasData = true
        }

        // 3. Activity analysis
        if let actPoints = trends[.activity], actPoints.count >= 3 {
            hasData = true
            let avg = actPoints.map(\.value).reduce(0, +) / Double(actPoints.count)
            activityNote = String(format: "Daily movement averaged approximately %.0f steps. In %@, gentle and comfortable activity tailored to your energy is recommended.", avg, profile.stage.badgeLabel)
        } else if let latestAct = readings[.activity] {
            activityNote = "Today's recorded activity is \(latestAct.formattedPrimaryValue) steps so far."
            hasData = true
        }

        if hasData {
            overallNote = "Observations are based entirely on your recorded wearable measurements and deterministic statistical comparisons. Wearable metrics do not establish clinical wellness."
        }

        return PersonalHealthSummary(
            generatedDate: Date(),
            periodTitle: "This Week's Observations",
            restingHeartRateObservation: hrNote,
            sleepObservation: sleepNote,
            activityObservation: activityNote,
            overallObservation: overallNote,
            isSufficientDataAvailable: hasData
        )
    }
}
