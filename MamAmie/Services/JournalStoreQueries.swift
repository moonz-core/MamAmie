import Foundation

extension JournalStore {
    /// Returns entries already sorted for the selected local day.
    func entries(for dayKey: String) -> [CalendarEntry] {
        entriesByDay[dayKey] ?? []
    }

    func timeline(for dayKey: String) -> [TimelineItem] {
        var items = entries(for: dayKey).map { entry in
            TimelineItem(
                id: "entry-\(entry.id.uuidString)",
                source: .entry(entry.id),
                category: entry.category,
                title: entry.title,
                summary: summary(for: entry),
                timeMinutes: entry.timeMinutes,
                status: status(for: entry),
                hasAttachment: !entry.attachments.isEmpty
            )
        }

        let doseItems = (doseLogsByDay[dayKey] ?? []).compactMap { log -> TimelineItem? in
            guard let schedule = medicationSchedulesByID[log.medicationID] else {
                return nil
            }

            return TimelineItem(
                id: "dose-\(log.id.uuidString)",
                source: .doseLog(log.id, schedule.sourceEntryID),
                category: .medication,
                title: schedule.name,
                summary: "Dose logged as \(log.status.displayName.lowercased())",
                timeMinutes: log.scheduledTimeMinutes,
                status: log.status.displayName,
                hasAttachment: false
            )
        }
        items.append(contentsOf: doseItems)

        return items.sorted(by: Self.sortTimelineItems)
    }

    func categoryIndicators(for dayKey: String) -> [EntryCategory] {
        EntryCategory.allCases.filter { categoriesByDay[dayKey]?.contains($0) == true }
    }

    func hasData(for dayKey: String) -> Bool {
        categoriesByDay[dayKey]?.isEmpty == false
    }

    func upcomingEntries(from dayKey: String, limit: Int = 4) -> [CalendarEntry] {
        let upcoming = entriesByDay
            .filter { $0.key >= dayKey }
            .flatMap { $0.value }
            .filter { [.appointment, .test, .medication, .task].contains($0.category) }
            .sorted(by: Self.sortEntries)

        return Array(upcoming.prefix(limit))
    }

    func doseLogs(for entry: CalendarEntry) -> [MedicationDoseLog] {
        guard let medicationID = entry.medicationID else { return [] }
        return doseLogsByMedication[medicationID] ?? []
    }

    func summary(for entry: CalendarEntry) -> String {
        switch entry.category {
        case .medication:
            guard let schedule = medicationSchedule(for: entry) else { return "Medication instructions" }
            return [schedule.dose, schedule.instructions]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        case .appointment:
            return entry.appointment?.clinicianOrClinic ?? "Care appointment"
        case .test:
            return entry.medicalRecord?.reportStatus.displayName ?? "Medical record"
        case .symptom:
            return entry.symptom?.severity.displayName ?? "Personal wellbeing note"
        case .food:
            return entry.food?.meal.displayName ?? "Food entry"
        case .journal:
            return entry.notes.isEmpty ? "Personal note" : entry.notes
        case .photo:
            return entry.attachments.isEmpty ? "Attachment" : "Photo attached"
        case .milestone:
            return "A moment in your journey"
        case .task:
            return entry.task?.completed == true ? "Completed" : "To do"
        }
    }

    func status(for entry: CalendarEntry) -> String? {
        switch entry.category {
        case .appointment: return entry.appointment?.status.displayName
        case .test: return entry.medicalRecord?.reportStatus.displayName
        case .task where entry.task?.completed == true: return "Completed"
        default: return nil
        }
    }

    static func sortEntries(_ lhs: CalendarEntry, _ rhs: CalendarEntry) -> Bool {
        if lhs.dayKey != rhs.dayKey { return lhs.dayKey < rhs.dayKey }
        switch (lhs.timeMinutes, rhs.timeMinutes) {
        case let (left?, right?):
            if left != right { return left < right }
        case (_?, nil): return true
        case (nil, _?): return false
        default: break
        }
        return lhs.createdAt < rhs.createdAt
    }

    static func sortTimelineItems(_ lhs: TimelineItem, _ rhs: TimelineItem) -> Bool {
        switch (lhs.timeMinutes, rhs.timeMinutes) {
        case let (left?, right?):
            if left != right { return left < right }
        case (_?, nil): return true
        case (nil, _?): return false
        default: break
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
