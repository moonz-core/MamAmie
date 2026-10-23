# MamAmie

MamAmie is an iOS app for pregnant women, built with SwiftUI.

## Open in Xcode

1. Open `MamAmie.xcodeproj` in Xcode 14 or newer.
2. Select the **MamAmie** scheme and an iPhone simulator (or a connected iPhone).
3. Press **Run** (`⌘R`).

The project uses iOS 16.0 as its minimum deployment target and has no external dependencies. The app's bundle identifier is `com.mamamie.app`; change it in the target's **Signing & Capabilities** settings before installing on a physical device or submitting to the App Store.

## Connected Health (Smartwatch & Maternal Health Monitoring)

MamAmie provides a dedicated **Connected Health** section integrating with Apple HealthKit and compatible wearables (such as Apple Watch).

### Supported Health Measurements

* **Heart Rate**: Latest heart rate, measurement timestamp, resting heart rate, and daily/weekly trend charts.
* **Blood Oxygen (SpO2)**: Latest saturation percentage and historical trends when supported by hardware (Apple Watch Series 6+).
* **Blood Pressure**: Systolic and diastolic records imported from authorized wireless BP monitors.
* **Sleep Duration**: Sleep pattern and rest summaries across trimesters.
* **Activity & Movement**: Daily step count and trends without rigid or uncontextualized athletic targets.
* **Heart Rate Variability (HRV)**: Autonomic tone trends (SDNN in ms) with educational notes.
* **Wrist Temperature**: Overnight variation trends (Apple Watch Series 8+ / Ultra), distinguished from clinical body thermometer readings.

### Testing & Simulation

* **Sample Demonstration Mode**: A dedicated toggle in Connected Health Settings (`⚙️`) allows developers and reviewers to test the complete maternal trend visualization and charts in the iOS Simulator or without a physical Apple Watch. All sample data is explicitly watermarked with a `Demo` tag so it is never confused with real medical records.
* **Privacy & Local Processing**: All HealthKit queries are read-only and processed entirely on-device. Health data is never transmitted to external servers or AI endpoints.
* **Medical Safety**: The application includes explicit clinical safety notices and emergency escalation guidance, emphasizing that wearables do not monitor fetal heart rate or diagnose pregnancy complications (e.g. preeclampsia).

