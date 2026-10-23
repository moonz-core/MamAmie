import Foundation

struct AttachmentReference: Codable, Identifiable, Equatable {
    let id: UUID
    let fileName: String
    let createdAt: Date
    let mediaType: String
}

struct AppointmentDetails: Codable, Equatable {
    var clinicianOrClinic: String = ""
    var location: String = ""
    var questions: String = ""
    var status: AppointmentStatus = .planned
}

struct MedicalRecordDetails: Codable, Equatable {
    var reportStatus: ReportStatus = .planned
    var followUpDayKey: String?
}

struct SymptomDetails: Codable, Equatable {
    var severity: SymptomSeverity = .mild
    var duration: String = ""
    var discussWithClinician: Bool = false
}

struct FoodDetails: Codable, Equatable {
    var meal: MealCategory = .other
    var ingredients: String = ""
    var portion: String = ""
}

struct JournalDetails: Codable, Equatable {
    var mood: String = ""
}

struct MilestoneDetails: Codable, Equatable {
    var isPersonal: Bool = true
}

struct TaskDetails: Codable, Equatable {
    var completed: Bool = false
}

struct CalendarEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var category: EntryCategory
    /// A local calendar day in yyyy-MM-dd format.
    var dayKey: String
    /// Minutes after midnight in the user's local calendar, when supplied.
    var timeMinutes: Int?
    var notes: String
    let createdAt: Date
    var modifiedAt: Date
    var attachments: [AttachmentReference]
    var medicationID: UUID?
    var appointment: AppointmentDetails?
    var medicalRecord: MedicalRecordDetails?
    var symptom: SymptomDetails?
    var food: FoodDetails?
    var journal: JournalDetails?
    var milestone: MilestoneDetails?
    var task: TaskDetails?
}
