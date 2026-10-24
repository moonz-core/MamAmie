import Combine
import Foundation

/// Observable domain store for the calendar journal.
/// Query indexes are maintained by the store so calendar rendering stays lightweight.
final class JournalStore: ObservableObject {
    @Published var entries: [CalendarEntry] = []
    @Published var medicationSchedules: [MedicationSchedule] = []
    @Published var doseLogs: [MedicationDoseLog] = []
    @Published var lastErrorMessage: String?

    let persistence: JournalPersistence
    var entriesByID: [UUID: CalendarEntry] = [:]
    var entriesByDay: [String: [CalendarEntry]] = [:]
    var medicationSchedulesByID: [UUID: MedicationSchedule] = [:]
    var doseLogsByDay: [String: [MedicationDoseLog]] = [:]
    var doseLogsByMedication: [UUID: [MedicationDoseLog]] = [:]
    var categoriesByDay: [String: Set<EntryCategory>] = [:]

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        persistence = JournalPersistence(fileManager: fileManager, storageURL: storageURL)
        load()
    }

    func entry(id: UUID) -> CalendarEntry? {
        entriesByID[id]
    }

    func medicationSchedule(for entry: CalendarEntry) -> MedicationSchedule? {
        guard let medicationID = entry.medicationID else { return nil }
        return medicationSchedulesByID[medicationID]
    }

    func attachmentData(for reference: AttachmentReference) -> Data? {
        persistence.data(for: reference)
    }

    func clearError() {
        lastErrorMessage = nil
    }

    func reset() {
        do {
            try persistence.removeAll()
            entries = []
            medicationSchedules = []
            doseLogs = []
            rebuildIndexes()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "We couldn't clear your journal data. Please try again."
        }
    }
}

struct StoreSnapshot {
    let entries: [CalendarEntry]
    let medicationSchedules: [MedicationSchedule]
    let doseLogs: [MedicationDoseLog]
}
