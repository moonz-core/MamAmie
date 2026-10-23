import Foundation

public enum MaternalStage: String, CaseIterable, Identifiable {
    case firstTrimester = "First Trimester"
    case secondTrimester = "Second Trimester"
    case thirdTrimester = "Third Trimester"
    case postpartum = "Postpartum Recovery"
    case planning = "Pregnancy Planning"

    public var id: String { rawValue }

    public var badgeLabel: String {
        switch self {
        case .firstTrimester: return "1st Trimester"
        case .secondTrimester: return "2nd Trimester"
        case .thirdTrimester: return "3rd Trimester"
        case .postpartum: return "Postpartum"
        case .planning: return "Planning"
        }
    }

    public var contextDescription: String {
        switch self {
        case .firstTrimester:
            return "Early circulatory adaptations begin as blood volume starts expanding. Fatigue and mild resting heart rate increases are very common."
        case .secondTrimester:
            return "Cardiac output peaks and systemic vascular resistance lowers. Many women experience restored daytime energy alongside steady cardiovascular changes."
        case .thirdTrimester:
            return "Resting heart rate remains elevated and sleep patterns often become lighter and fragmented due to physical comfort factors."
        case .postpartum:
            return "Your cardiovascular system and resting heart rate gradually return toward your pre-pregnancy baseline over weeks and months."
        case .planning:
            return "Establishing your natural personal baselines for resting heart rate, sleep consistency, and gentle activity supports pre-conception wellness."
        }
    }
}

public struct MaternalHealthProfile: Equatable {
    public var stage: MaternalStage
    public var gestationalWeek: Int?
    public var userName: String

    public init(
        stage: MaternalStage = .firstTrimester,
        gestationalWeek: Int? = 12,
        userName: String = "Mama"
    ) {
        self.stage = stage
        self.gestationalWeek = gestationalWeek
        self.userName = userName
    }

    public var formattedStageSubtitle: String {
        if let week = gestationalWeek, stage != .postpartum && stage != .planning {
            return "Week \(week) • \(stage.badgeLabel)"
        }
        return stage.rawValue
    }
}
