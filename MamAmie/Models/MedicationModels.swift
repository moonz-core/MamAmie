import Foundation

struct MedicationSchedule: Codable, Identifiable, Equatable {
    let id: UUID
    let sourceEntryID: UUID
    var name: String
    var dose: String
    var instructions: String
    var recurrence: String
    var createdAt: Date
    var modifiedAt: Date
}

struct MedicationDoseLog: Codable, Identifiable, Equatable {
    let id: UUID
    let medicationID: UUID
    let dayKey: String
    let scheduledTimeMinutes: Int?
    let actualLoggedAt: Date
    var status: DoseStatus
    var notes: String
}

struct JournalStoreData: Codable {
    var entries: [CalendarEntry] = []
    var medicationSchedules: [MedicationSchedule] = []
    var doseLogs: [MedicationDoseLog] = []
}
