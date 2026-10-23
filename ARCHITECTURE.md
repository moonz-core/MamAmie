# MamAmie Architecture Guidelines

These guidelines apply to future work in MamAmie, including the Calendar & Pregnancy Journal feature.

## Keep files focused

Do not place an entire feature in one large Swift file. Prefer one primary responsibility per file:

- `Models/` contains Codable domain models, enums, and date/value types.
- `Services/` contains persistence, indexing, and domain-store operations.
- `Views/` contains screen composition and focused reusable SwiftUI components.
- `Assets.xcassets/` contains visual assets only.

A screen may compose several smaller views, but reusable rows, sections, forms, and detail components should live in their own files when they have meaningful behavior or styling.

## State and persistence

- Keep persistence behind a service/store boundary; views should not read or write files directly.
- Use stable IDs for records and attachments.
- Store date-only records using local calendar-day keys, not formatted display strings or UTC timestamps.
- Keep category-specific data in explicit models while using a shared calendar-entry interface.
- Preserve user input when a save fails and expose a friendly error state.

## Performance

- Index records by stable identifiers, local day keys, and other frequently queried relationships.
- Avoid scanning the complete journal for every calendar cell or SwiftUI row update.
- Keep expensive work out of `body`; derive small, focused view data in the store or a dedicated view model.
- Avoid synchronous repeated image decoding in frequently recomputed views.
- Do not introduce large dependencies or an architecture migration without a concrete need.

## Sensitive health data

- Keep journal data and attachments local unless an explicit, privacy-reviewed backend exists.
- Never log medical notes, prescriptions, symptoms, pregnancy dates, or attachment contents.
- Do not invent pregnancy dates, gestational age, medical guidance, or treatment decisions.
- Keep notification content privacy-safe and only schedule notifications after explicit user configuration.

## Adding a new feature

Before implementation, inspect the existing architecture and write a short plan. Reuse existing models and services where possible. Add focused tests for date calculations, persistence, and domain behavior when a test target is available.
