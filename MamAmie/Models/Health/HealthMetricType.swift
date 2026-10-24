import Foundation
import SwiftUI
import HealthKit

public enum HealthMetricType: String, CaseIterable, Identifiable, Sendable {
    case heartRate = "heart_rate"
    case bloodOxygen = "blood_oxygen"
    case bloodPressure = "blood_pressure"
    case sleep = "sleep"
    case activity = "activity"
    case heartRateVariability = "hrv"
    case wristTemperature = "wrist_temperature"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .bloodOxygen:
            return "Blood Oxygen"
        case .bloodPressure:
            return "Blood Pressure"
        case .sleep:
            return "Sleep Duration"
        case .activity:
            return "Daily Steps"
        case .heartRateVariability:
            return "Heart Rate Variability"
        case .wristTemperature:
            return "Wrist Temperature"
        }
    }

    public var shortTitle: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .bloodOxygen: return "Blood Oxygen"
        case .bloodPressure: return "Blood Pressure"
        case .sleep: return "Sleep"
        case .activity: return "Steps"
        case .heartRateVariability: return "HRV"
        case .wristTemperature: return "Wrist Temp"
        }
    }

    public var defaultUnit: String {
        switch self {
        case .heartRate: return "BPM"
        case .bloodOxygen: return "%"
        case .bloodPressure: return "mmHg"
        case .sleep: return "hrs"
        case .activity: return "steps"
        case .heartRateVariability: return "ms"
        case .wristTemperature: return "°C"
        }
    }

    public func formattedValue(_ value: Double) -> String {
        switch self {
        case .bloodOxygen:
            return String(format: "%.0f", value <= 1.0 ? value * 100.0 : value)
        case .sleep:
            return String(format: "%.1f", value)
        case .activity:
            return NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal)
        case .wristTemperature:
            return String(format: "%.1f", value)
        default:
            return String(format: "%.0f", value)
        }
    }

    public var iconName: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .bloodOxygen: return "lungs.fill"
        case .bloodPressure: return "gauge.with.needle.fill"
        case .sleep: return "moon.stars.fill"
        case .activity: return "figure.walk"
        case .heartRateVariability: return "waveform.path.ecg"
        case .wristTemperature: return "thermometer.medium"
        }
    }

    public var iconTintColor: Color {
        switch self {
        case .heartRate:
            return Color(red: 0.90, green: 0.28, blue: 0.42) // Warm Rose Coral
        case .bloodOxygen:
            return Color(red: 0.18, green: 0.62, blue: 0.88) // Calming Cyan Blue
        case .bloodPressure:
            return Color(red: 0.62, green: 0.35, blue: 0.82) // Royal Plum
        case .sleep:
            return Color(red: 0.38, green: 0.45, blue: 0.78) // Twilight Indigo
        case .activity:
            return Color(red: 0.24, green: 0.72, blue: 0.58) // Sage Mint
        case .heartRateVariability:
            return Color(red: 0.85, green: 0.45, blue: 0.25) // Gentle Ochre Amber
        case .wristTemperature:
            return Color(red: 0.88, green: 0.54, blue: 0.32) // Soft Peach Terracotta
        }
    }

    public var sampleQuantityType: HKQuantityType? {
        switch self {
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .bloodOxygen:
            return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case .bloodPressure:
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        case .sleep:
            return nil
        case .activity:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .heartRateVariability:
            return HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case .wristTemperature:
            if #available(iOS 16.0, *) {
                return HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)
            } else {
                return HKQuantityType.quantityType(forIdentifier: .bodyTemperature)
            }
        }
    }

    public var categoryType: HKCategoryType? {
        switch self {
        case .sleep:
            return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        default:
            return nil
        }
    }

    public var deviceCompatibilityNotice: String {
        switch self {
        case .heartRate:
            return "Measured automatically by Apple Watch and compatible heart rate monitors throughout the day."
        case .bloodOxygen:
            return "Recorded periodically in the background or on-demand by Apple Watch Series 6 or later (where feature is available and authorized)."
        case .bloodPressure:
            return "Recorded via compatible connected blood pressure monitors synced to Apple Health. Apple Watch does not directly measure blood pressure."
        case .sleep:
            return "Calculated when wearing Apple Watch to bed with Sleep tracking turned on, or from third-party sleep monitors synced to Apple Health."
        case .activity:
            return "Tracked automatically via your iPhone motion coprocessor or Apple Watch."
        case .heartRateVariability:
            return "Captured in milliseconds (SDNN) by Apple Watch during periods of rest and mindfulness."
        case .wristTemperature:
            return "Recorded during sleep on Apple Watch Series 8 or Ultra. This reflects wrist skin temperature variations, not core body temperature."
        }
    }

    public var maternalContextDescription: String {
        switch self {
        case .heartRate:
            return "During pregnancy, your resting heart rate typically rises by 10 to 15 beats per minute as your blood volume increases to nourish your baby. This is a common physiological adaptation."
        case .bloodOxygen:
            return "Blood oxygen levels (SpO2) generally stay consistent throughout pregnancy (typically 95-100%). It is not continuously monitored unless your device specifically performs background checks."
        case .bloodPressure:
            return "Blood pressure often drops slightly in the first and second trimesters before returning to your baseline near term. Tracking it with a validated clinical cuff helps your care team watch for preeclampsia."
        case .sleep:
            return "Hormonal shifts, frequent bathroom trips, and physical changes often alter sleep quality. Aim for restful downtime rather than stressing about perfection."
        case .activity:
            return "Gentle daily movement supports circulation, mood, and stamina. There is no universal pregnancy target—listen to your body and adjust to how you feel."
        case .heartRateVariability:
            return "HRV measures the small variations between heartbeats. It naturally fluctuates with stress, recovery, and pregnancy progression. It is not an isolated diagnostic measure."
        case .wristTemperature:
            return "Overnight wrist temperature helps track subtle cyclical shifts and sleep patterns. It is distinct from clinical oral or tympanic thermometers used to evaluate a fever."
        }
    }

    public var permissionRationale: String {
        switch self {
        case .heartRate:
            return "Allows MamAmie to track resting and daily heart-rate trends to reflect common maternal cardiovascular changes."
        case .bloodOxygen:
            return "Allows you to view recorded oxygen saturation readings from compatible wearable checks."
        case .bloodPressure:
            return "Displays systolic and diastolic records logged from your home blood pressure cuff."
        case .sleep:
            return "Helps you monitor your rest duration and trends as your body changes through each trimester."
        case .activity:
            return "Provides gentle insight into your daily movement and step patterns without harsh targets."
        case .heartRateVariability:
            return "Shows autonomic nervous tone trends and recovery balance over time."
        case .wristTemperature:
            return "Displays overnight wrist temperature variations recorded while sleeping."
        }
    }
}
