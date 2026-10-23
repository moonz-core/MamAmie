import Foundation

enum EntryCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case medication
    case appointment
    case test
    case symptom
    case food
    case journal
    case photo
    case milestone
    case task

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .medication: return "Medication or supplement"
        case .appointment: return "Doctor appointment"
        case .test: return "Medical test or report"
        case .symptom: return "Symptoms and wellbeing"
        case .food: return "Food and nutrition"
        case .journal: return "Personal journal"
        case .photo: return "Photograph or attachment"
        case .milestone: return "Pregnancy milestone"
        case .task: return "Task or reminder"
        }
    }

    var shortName: String {
        switch self {
        case .medication: return "Medication"
        case .appointment: return "Appointment"
        case .test: return "Test or report"
        case .symptom: return "Wellbeing"
        case .food: return "Food"
        case .journal: return "Journal"
        case .photo: return "Photo"
        case .milestone: return "Milestone"
        case .task: return "Task"
        }
    }

    var systemImage: String {
        switch self {
        case .medication: return "pill.fill"
        case .appointment: return "stethoscope"
        case .test: return "doc.text.magnifyingglass"
        case .symptom: return "waveform.path.ecg"
        case .food: return "fork.knife"
        case .journal: return "book.closed.fill"
        case .photo: return "photo.fill"
        case .milestone: return "star.fill"
        case .task: return "checklist"
        }
    }
}
