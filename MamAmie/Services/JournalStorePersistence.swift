import Foundation

extension JournalStore {
    func load() {
        do {
            let stored = try persistence.load()
            entries = stored.entries
            medicationSchedules = stored.medicationSchedules
            doseLogs = stored.doseLogs
            rebuildIndexes()
        } catch {
            lastErrorMessage = "We couldn't load your saved journal. You can continue, but new changes may need to be saved again."
        }
    }

    func persist() throws {
        try persistence.save(JournalStoreData(
            entries: entries,
            medicationSchedules: medicationSchedules,
            doseLogs: doseLogs
        ))
    }

    func rebuildIndexes() {
        entriesByID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { current, _ in current })
        entriesByDay = Dictionary(grouping: entries, by: \.dayKey)
            .mapValues { $0.sorted(by: Self.sortEntries) }
        medicationSchedulesByID = Dictionary(
            medicationSchedules.map { ($0.id, $0) },
            uniquingKeysWith: { current, _ in current }
        )
        doseLogsByDay = Dictionary(grouping: doseLogs, by: \.dayKey)
            .mapValues { $0.sorted { $0.actualLoggedAt < $1.actualLoggedAt } }
        doseLogsByMedication = Dictionary(grouping: doseLogs, by: \.medicationID)
            .mapValues { $0.sorted { $0.actualLoggedAt > $1.actualLoggedAt } }

        var categories = Dictionary(grouping: entries, by: \.dayKey)
            .mapValues { Set($0.map(\.category)) }
        for dayKey in doseLogsByDay.keys {
            categories[dayKey, default: []].insert(.medication)
        }
        categoriesByDay = categories
    }

    func restore(_ snapshot: StoreSnapshot) {
        entries = snapshot.entries
        medicationSchedules = snapshot.medicationSchedules
        doseLogs = snapshot.doseLogs
        rebuildIndexes()
    }
}
