# MamAmie Apple Watch companion

This is a native watchOS 9+ app embedded in the existing MamAmie iOS app. It reuses the iPhone app's AccentColor, journal appointments, and medication schedules. It does not show a pregnancy week or mode because the current iPhone app has no persisted pregnancy-dating or pregnancy-loss profile to share.

## Implemented

- A compact MamAmie home with shared upcoming appointments and medication occurrences.
- User-initiated Apple Health authorization and a recent maternal heart-rate history chart. The metric is explicitly the wearer's heart rate, never fetal heart rate.
- Locally persisted movement-count and contraction-timing sessions with clear clinician-guidance and urgent-contact limitations.
- A configurable water log with an optional personal target, quick add, and undo.
- Quick postpartum/newborn organization notes and user-reported medication dose statuses.
- WatchConnectivity latest-state snapshots and queued, idempotent watch actions. Medication statuses also enter the existing iPhone JournalStore when the exact schedule occurrence still exists.

## Data and limitations

The phone shares only its upcoming care entries. Watch-created activity is retained in watch-local UserDefaults while queued and copied to the phone's private Application Support store after receipt; the current iPhone app has no diary views/models for movement, contractions, hydration, or newborn quick notes. Those activity payloads are therefore stored for handoff but are not yet visible in the iPhone UI. Dose statuses use the existing iPhone dose-log model. Sync is opportunistic through WatchConnectivity; an iPhone connection is needed for phone-side persistence.

Pregnancy dating, postpartum mode selection, and pregnancy-loss mode are not implemented in the current iPhone app, so this companion does not infer them. It does not prescribe hydration targets, count targets, medicines, or clinical thresholds. HealthKit may return no samples when access is denied; Apple's privacy model does not let the app distinguish denial from an empty result for read-only data.

No complications, scheduled notifications, newborn feeding duration/side details, or remote backend sync are included in this first local-first implementation. Add those only after the iPhone app has corresponding models/preferences and product-reviewed behavior.

## Build

Open `MamAmie.xcodeproj` in Xcode 15 or later, select the `MamAmie` scheme, and build for an iPhone simulator/device with a paired Watch simulator/device. The project defines a separate `MamAmie Watch` target using watchOS 9. HealthKit access on a physical device requires the user to grant access in the watch app.
