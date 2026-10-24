import Foundation

extension JournalStore {
    @discardableResult
    func upsertEntry(
        _ entry: CalendarEntry,
        medicationSchedule: MedicationSchedule? = nil,
        attachmentData: Data? = nil
    ) -> Bool {
        let previousState = StoreSnapshot(
            entries: entries,
            medicationSchedules: medicationSchedules,
            doseLogs: doseLogs
        )
        var savedAttachment: AttachmentReference?
        var updatedEntry = entry

        do {
            if let attachmentData {
                let reference = try persistence.saveAttachment(attachmentData)
                savedAttachment = reference
                updatedEntry.attachments.append(reference)
            }

            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            } else {
                entries.append(updatedEntry)
            }

            if let medicationSchedule {
                if let index = medicationSchedules.firstIndex(where: { $0.id == medicationSchedule.id }) {
                    medicationSchedules[index] = medicationSchedule
                } else {
                    medicationSchedules.append(medicationSchedule)
                }
            }

            rebuildIndexes()
            try persist()
            return true
        } catch {
            restore(previousState)
            if let savedAttachment {
                persistence.deleteAttachment(savedAttachment)
            }
            lastErrorMessage = "We couldn't save this entry. Your information is still on screen; please try again."
            return false
        }
    }

    @discardableResult
    func deleteEntry(id: UUID) -> Bool {
        guard let entry = entry(id: id) else { return false }

        let previousState = StoreSnapshot(
            entries: entries,
            medicationSchedules: medicationSchedules,
            doseLogs: doseLogs
        )
        entries.removeAll { $0.id == id }

        if let medicationID = entry.medicationID {
            medicationSchedules.removeAll { $0.id == medicationID }
            doseLogs.removeAll { $0.medicationID == medicationID }
        }

        do {
            rebuildIndexes()
            try persist()
            entry.attachments.forEach { persistence.deleteAttachment($0) }
            return true
        } catch {
            restore(previousState)
            lastErrorMessage = "We couldn't delete this entry. Please try again."
            return false
        }
    }

    @discardableResult
    func removeAttachment(entryID: UUID, attachmentID: UUID) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == entryID }),
              let reference = entries[index].attachments.first(where: { $0.id == attachmentID }) else {
            return false
        }

        let previousState = StoreSnapshot(
            entries: entries,
            medicationSchedules: medicationSchedules,
            doseLogs: doseLogs
        )
        entries[index].attachments.removeAll { $0.id == attachmentID }
        entries[index].modifiedAt = Date()

        do {
            rebuildIndexes()
            try persist()
            persistence.deleteAttachment(reference)
            return true
        } catch {
            restore(previousState)
            lastErrorMessage = "We couldn't remove that attachment. Please try again."
            return false
        }
    }

    @discardableResult
    func logDose(
        for entry: CalendarEntry,
        status: DoseStatus,
        notes: String = "",
        id: UUID = UUID(),
        actualLoggedAt: Date = Date(),
        dayKey: String? = nil
    ) -> Bool {
        guard let medicationID = entry.medicationID,
              medicationSchedulesByID[medicationID] != nil else {
            lastErrorMessage = "This medication schedule is no longer available."
            return false
        }
        if doseLogs.contains(where: { $0.id == id }) { return true }

        let log = MedicationDoseLog(
            id: id,
            medicationID: medicationID,
            dayKey: dayKey ?? entry.dayKey,
            scheduledTimeMinutes: entry.timeMinutes,
            actualLoggedAt: actualLoggedAt,
            status: status,
            notes: notes
        )
        let previousState = StoreSnapshot(
            entries: entries,
            medicationSchedules: medicationSchedules,
            doseLogs: doseLogs
        )
        doseLogs.append(log)

        do {
            rebuildIndexes()
            try persist()
            return true
        } catch {
            restore(previousState)
            lastErrorMessage = "We couldn't save the dose log. Please try again."
            return false
        }
    }
}
