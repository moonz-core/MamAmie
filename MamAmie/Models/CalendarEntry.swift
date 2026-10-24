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
    var calories: Double? = nil
    var proteinG: Double? = nil
    var carbsG: Double? = nil
    var fatG: Double? = nil
    var fiberG: Double? = nil
    var ironMg: Double? = nil
    var folateMcg: Double? = nil
    var calciumMg: Double? = nil
    var vitaminDMcg: Double? = nil
    var suggestedSupplements: [String] = []
    var suggestedFoods: [String] = []
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

struct WeightDetails: Codable, Equatable {
    var weightKg: Double
    var unit: String = "kg"
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
    var weight: WeightDetails?

    init(
        id: UUID = UUID(),
        title: String,
        category: EntryCategory,
        dayKey: String,
        timeMinutes: Int? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        attachments: [AttachmentReference] = [],
        medicationID: UUID? = nil,
        appointment: AppointmentDetails? = nil,
        medicalRecord: MedicalRecordDetails? = nil,
        symptom: SymptomDetails? = nil,
        food: FoodDetails? = nil,
        journal: JournalDetails? = nil,
        milestone: MilestoneDetails? = nil,
        task: TaskDetails? = nil,
        weight: WeightDetails? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.dayKey = dayKey
        self.timeMinutes = timeMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.attachments = attachments
        self.medicationID = medicationID
        self.appointment = appointment
        self.medicalRecord = medicalRecord
        self.symptom = symptom
        self.food = food
        self.journal = journal
        self.milestone = milestone
        self.task = task
        self.weight = weight
    }
}
