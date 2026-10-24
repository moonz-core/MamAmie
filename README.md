# MamAmie

MamAmie is an iOS app for pregnant women, built with SwiftUI.

## Open in Xcode

1. Open `MamAmie.xcodeproj` in Xcode 14 or newer.
2. Select the **MamAmie** scheme and an iPhone simulator (or a connected iPhone).
3. Press **Run** (`⌘R`).

The project uses iOS 16.0 as its minimum deployment target and has no external dependencies. The app's bundle identifier is `com.mamamie.app`; change it in the target's **Signing & Capabilities** settings before installing on a physical device or submitting to the App Store.

## Onboarding

The `feature/onboarding` branch adds a complete local onboarding flow for the iOS app. It covers:

- Welcome and privacy explanation.
- Journey stage selection: preparing for pregnancy, currently pregnant, or postpartum support.
- Optional pregnancy dating using a clinician-provided due date or the first day of the last period.
- Deterministic estimated due-date and gestational-week calculations when reliable dates are supplied.
- Optional display name personalization.
- Local privacy acknowledgment and a review screen before completion.
- Persistence across launches using a Codable file in the app's private Application Support directory.
- Launch gating so first-time users complete onboarding before the main tabs open.
- Profile access to review and update onboarding answers.

No authentication or remote onboarding API exists in this iOS branch, so answers are intentionally stored locally in the app sandbox. HealthKit permission is still requested contextually from Connected Health rather than during onboarding.

## Backend API & Cloud Services

The MamAmie AI backend is deployed live on Render:

* **Live API Base URL:** `https://mamamie.onrender.com/api/v1`
* **Interactive OpenAPI (Swagger):** [https://mamamie.onrender.com/docs](https://mamamie.onrender.com/docs)
* **Health Check Endpoint:** [https://mamamie.onrender.com/health](https://mamamie.onrender.com/health)

Full backend documentation, database models, and local setup instructions are available in the [backend/](backend/) directory.

## Project structure

The project follows a focused, feature-oriented structure. Domain models live in `MamAmie/Models`, persistence and indexed journal operations live in `MamAmie/Services`, and the calendar UI is split into screen-level and reusable component files under `MamAmie/Views`. See `ARCHITECTURE.md` before adding new functionality; large all-in-one Swift files are intentionally avoided.

## Calendar & Pregnancy Journal

The **Calendar** tab provides a local, date-based journal:

- Month navigation, selectable days, today navigation, leap-year-safe date handling, and entry indicators.
- Persistent create, edit, view, and delete flows for medication, appointments, tests/reports, symptoms, food, journal notes, photos, milestones, and tasks.
- Chronological daily timeline and upcoming saved care items.
- Medication schedules are stored separately from dose logs, with Taken, Skipped, and Not yet confirmed actions.
- Selected images are copied into the app's private Application Support directory and referenced by stable IDs. They are not uploaded.

Records are stored locally in `Application Support/MamAmie/journal.json`. Date-only records use a local `yyyy-MM-dd` day key instead of a UTC timestamp so navigation across time zones and daylight-saving boundaries does not move an entry to another day.

Pregnancy dating, authentication/user accounts, cloud sync, reviewed educational content, and local notifications are intentionally not fabricated or enabled yet. The current calendar remains useful without pregnancy dates and does not infer a gestational week. Notification scheduling is the recommended next feature after the core calendar has been tested on-device.

## Connected Health (Smartwatch & Maternal Health Monitoring)

MamAmie provides a dedicated **Connected Health** section integrating with Apple HealthKit and compatible wearables (such as Apple Watch).

### Supported Health Measurements

* **Heart Rate**: Latest heart rate, measurement timestamp, resting heart rate, and daily/weekly trend charts.
* **Readable trend graphs**: Chart axes use real local `Date` values, with date labels for week/month views, time labels for day views, and timestamped readings below each graph.
* **Pregnancy context comparison**: Detail screens show a clearly labeled, broad non-diagnostic pregnancy reference comparison beneath the graph when the user's stage is pregnancy-related. This is contextual information, not a medical target or diagnosis.
* **Blood Oxygen (SpO2)**: Latest saturation percentage and historical trends when supported by hardware (Apple Watch Series 6+).
* **Blood Pressure**: Systolic and diastolic records imported from authorized wireless BP monitors.
* **Sleep Duration**: Sleep pattern and rest summaries across trimesters.
* **Activity & Movement**: Daily step count and trends without rigid or uncontextualized athletic targets.
* **Heart Rate Variability (HRV)**: Autonomic tone trends (SDNN in ms) with educational notes.
* **Wrist Temperature**: Overnight variation trends (Apple Watch Series 8+ / Ultra), distinguished from clinical body thermometer readings.

### Testing & Simulation

* **Sample Demonstration Mode**: A dedicated toggle in Connected Health Settings allows developers and reviewers to test the complete maternal trend visualization and charts in the iOS Simulator or without a physical Apple Watch. All sample data is explicitly watermarked with a `Demo` tag so it is never confused with real medical records.
* **Privacy & Local Processing**: All HealthKit queries are read-only and processed entirely on-device. Health data is never transmitted to external servers or AI endpoints.
* **Medical Safety**: The application includes explicit clinical safety notices and emergency escalation guidance, emphasizing that wearables do not monitor fetal heart rate or diagnose pregnancy complications (e.g. preeclampsia).
