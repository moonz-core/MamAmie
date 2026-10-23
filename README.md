# MamAmie

MamAmie is an iOS app for pregnant women, built with SwiftUI.

## Open in Xcode

1. Open `MamAmie.xcodeproj` in Xcode 14 or newer.
2. Select the **MamAmie** scheme and an iPhone simulator (or a connected iPhone).
3. Press **Run** (`⌘R`).

The project uses iOS 16.0 as its minimum deployment target and has no external dependencies. The app's bundle identifier is `com.mamamie.app`; change it in the target's **Signing & Capabilities** settings before installing on a physical device or submitting to the App Store.

## Project structure

The project follows a focused, feature-oriented structure. Domain models live in `MamAmie/Models`, persistence and indexed journal operations live in `MamAmie/Services`, and the calendar UI is split into screen-level and reusable component files under `MamAmie/Views`. See `ARCHITECTURE.md` before adding new functionality; large all-in-one Swift files are intentionally avoided.

## Calendar & Pregnancy Journal

The **Calendar** tab on the `feature/calendar` branch provides a local, date-based journal:

- Month navigation, selectable days, today navigation, leap-year-safe date handling, and entry indicators.
- Persistent create, edit, view, and delete flows for medication, appointments, tests/reports, symptoms, food, journal notes, photos, milestones, and tasks.
- Chronological daily timeline and upcoming saved care items.
- Medication schedules are stored separately from dose logs, with Taken, Skipped, and Not yet confirmed actions.
- Selected images are copied into the app's private Application Support directory and referenced by stable IDs. They are not uploaded.

Records are stored locally in `Application Support/MamAmie/journal.json`. Date-only records use a local `yyyy-MM-dd` day key instead of a UTC timestamp so navigation across time zones and daylight-saving boundaries does not move an entry to another day.

Pregnancy dating, authentication/user accounts, cloud sync, reviewed educational content, and local notifications are intentionally not fabricated or enabled yet. The current calendar remains useful without pregnancy dates and does not infer a gestational week. Notification scheduling is the recommended next feature after the core calendar has been tested on-device.
