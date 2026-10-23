import Foundation

struct EntryFormState {
    var id: UUID
    var createdAt: Date
    var date: Date
    var time: Date
    var includesTime: Bool
    var title: String
    var notes: String
    var dose: String
    var instructions: String
    var recurrence: String
    var clinicianOrClinic: String
    var location: String
    var questions: String
    var appointmentStatus: AppointmentStatus
    var reportStatus: ReportStatus
    var includesFollowUpDate: Bool
    var followUpDate: Date
    var symptomSeverity: SymptomSeverity
    var duration: String
    var discussWithClinician: Bool
    var meal: MealCategory
    var ingredients: String
    var portion: String
    var mood: String
    var isPersonalMilestone: Bool
    var taskCompleted: Bool

    init(entry: CalendarEntry?, store: JournalStore, fallbackDate: Date) {
        let initialDate = entry.flatMap { LocalDay.date(from: $0.dayKey) } ?? fallbackDate
        let initialTime = entry.flatMap { existing in
            existing.timeMinutes.flatMap { LocalDay.date(for: $0, on: existing.dayKey) }
        } ?? initialDate
        let appointment = entry?.appointment
        let medicalRecord = entry?.medicalRecord
        let symptom = entry?.symptom
        let food = entry?.food
        let journal = entry?.journal
        let milestone = entry?.milestone
        let task = entry?.task
        let followUp = medicalRecord?.followUpDayKey.flatMap { LocalDay.date(from: $0) }

        id = entry?.id ?? UUID()
        createdAt = entry?.createdAt ?? Date()
        date = initialDate
        time = initialTime
        includesTime = entry?.timeMinutes != nil
        title = entry?.title ?? ""
        notes = entry?.notes ?? ""
        dose = entry.flatMap { store.medicationSchedule(for: $0)?.dose } ?? ""
        instructions = entry.flatMap { store.medicationSchedule(for: $0)?.instructions } ?? ""
        recurrence = entry.flatMap { store.medicationSchedule(for: $0)?.recurrence } ?? ""
        clinicianOrClinic = appointment?.clinicianOrClinic ?? ""
        location = appointment?.location ?? ""
        questions = appointment?.questions ?? ""
        appointmentStatus = appointment?.status ?? .planned
        reportStatus = medicalRecord?.reportStatus ?? .planned
        includesFollowUpDate = followUp != nil
        followUpDate = followUp ?? initialDate
        symptomSeverity = symptom?.severity ?? .mild
        duration = symptom?.duration ?? ""
        discussWithClinician = symptom?.discussWithClinician ?? false
        meal = food?.meal ?? .other
        ingredients = food?.ingredients ?? ""
        portion = food?.portion ?? ""
        mood = journal?.mood ?? ""
        isPersonalMilestone = milestone?.isPersonal ?? true
        taskCompleted = task?.completed ?? false
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeEntry(
        category: EntryCategory,
        existingEntry: CalendarEntry?,
        now: Date
    ) -> CalendarEntry {
        CalendarEntry(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            dayKey: LocalDay.key(for: date),
            timeMinutes: includesTime ? LocalDay.minutes(for: time) : nil,
            notes: notes,
            createdAt: createdAt,
            modifiedAt: now,
            attachments: existingEntry?.attachments ?? [],
            medicationID: category == .medication ? (existingEntry?.medicationID ?? UUID()) : nil,
            appointment: category == .appointment ? AppointmentDetails(
                clinicianOrClinic: clinicianOrClinic,
                location: location,
                questions: questions,
                status: appointmentStatus
            ) : nil,
            medicalRecord: category == .test ? MedicalRecordDetails(
                reportStatus: reportStatus,
                followUpDayKey: includesFollowUpDate ? LocalDay.key(for: followUpDate) : nil
            ) : nil,
            symptom: category == .symptom ? SymptomDetails(
                severity: symptomSeverity,
                duration: duration,
                discussWithClinician: discussWithClinician
            ) : nil,
            food: category == .food ? FoodDetails(
                meal: meal,
                ingredients: ingredients,
                portion: portion
            ) : nil,
            journal: category == .journal ? JournalDetails(mood: mood) : nil,
            milestone: category == .milestone ? MilestoneDetails(isPersonal: isPersonalMilestone) : nil,
            task: category == .task ? TaskDetails(completed: taskCompleted) : nil
        )
    }
}
