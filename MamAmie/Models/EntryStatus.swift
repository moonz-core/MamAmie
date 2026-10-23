import Foundation

enum AppointmentStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case planned
    case scheduled
    case completed
    case rescheduled
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .scheduled: return "Scheduled"
        case .completed: return "Completed"
        case .rescheduled: return "Rescheduled"
        case .cancelled: return "Cancelled"
        }
    }
}

enum ReportStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case planned
    case testCompleted
    case reportPending
    case reportReceived
    case followUpNeeded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .testCompleted: return "Test completed"
        case .reportPending: return "Report pending"
        case .reportReceived: return "Report received"
        case .followUpNeeded: return "Follow-up needed"
        }
    }
}

enum SymptomSeverity: String, Codable, CaseIterable, Identifiable, Hashable {
    case mild
    case moderate
    case severe

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum MealCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast
    case lunch
    case dinner
    case snack
    case other

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum DoseStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case taken
    case skipped
    case notConfirmed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taken: return "Taken"
        case .skipped: return "Skipped"
        case .notConfirmed: return "Not yet confirmed"
        }
    }
}
