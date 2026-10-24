import Foundation

/// Small, privacy-conscious payloads shared by the phone and watch targets.
struct WatchCompanionSnapshot: Codable {
    var updatedAt: Date
    var appointments: [WatchAppointment]
    var medications: [WatchMedication]
}

struct WatchAppointment: Codable, Identifiable {
    var id: String
    var title: String
    var date: Date
    var timeMinutes: Int?
    var location: String?
}

struct WatchMedication: Codable, Identifiable {
    /// The calendar occurrence ID, used by SwiftUI for stable row identity.
    var id: String
    /// Existing JournalStore medication schedule ID.
    var scheduleID: String
    var name: String
    var dose: String
    var instructions: String
    var scheduledDate: Date
    var timeMinutes: Int?
}

enum WatchActionKind: String, Codable, Equatable {
    case hydration
    case kickSession
    case contractionSession
    case medicationDose
    case feeding
    case diaper
    case sleepSession
    case recoveryCheckIn
}

/// User-entered wrist activity. The UUID is stable across transfer retries.
struct WatchCompanionAction: Codable, Identifiable {
    var id: UUID
    var kind: WatchActionKind
    var occurredAt: Date
    var dayKey: String
    var amountMillilitres: Int?
    var scheduleID: String?
    var occurrenceID: String?
    var doseStatus: String?
    var title: String
    var detail: String
}
