import Foundation

public enum OnboardingStage: String, Codable, CaseIterable, Identifiable, Equatable {
    case planning
    case pregnant
    case postpartum

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .planning: return "Preparing for pregnancy"
        case .pregnant: return "Currently pregnant"
        case .postpartum: return "Postpartum support"
        }
    }

    public var subtitle: String {
        switch self {
        case .planning: return "Support for getting ready, at your own pace."
        case .pregnant: return "A calm place to follow your personal journey."
        case .postpartum: return "Gentle support as you recover and adjust."
        }
    }

    public var badgeLabel: String {
        switch self {
        case .planning: return "Planning"
        case .pregnant: return "Pregnancy"
        case .postpartum: return "Postpartum"
        }
    }

    public var iconName: String {
        switch self {
        case .planning: return "sparkles"
        case .pregnant: return "figure.and.child.holdinghands"
        case .postpartum: return "heart.circle.fill"
        }
    }
}

public enum PregnancyDatingMethod: String, Codable, CaseIterable, Identifiable, Equatable {
    case dueDate
    case lastPeriod
    case notSet

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dueDate: return "I know my due date"
        case .lastPeriod: return "I know the first day of my last period"
        case .notSet: return "I want to add dates later"
        }
    }

    public var detail: String {
        switch self {
        case .dueDate: return "Use the date provided by your healthcare professional."
        case .lastPeriod: return "We will estimate a due date using a standard 280-day calculation."
        case .notSet: return "You can still use MamAmie without pregnancy dates."
        }
    }
}

public struct OnboardingProfile: Codable, Equatable {
    public let displayName: String
    public let stage: OnboardingStage
    public let datingMethod: PregnancyDatingMethod
    public let dueDate: Date?
    public let lastPeriodDate: Date?
    public let privacyAcknowledgedAt: Date
    public let completedAt: Date

    public init(
        displayName: String,
        stage: OnboardingStage,
        datingMethod: PregnancyDatingMethod,
        dueDate: Date?,
        lastPeriodDate: Date?,
        privacyAcknowledgedAt: Date,
        completedAt: Date
    ) {
        self.displayName = displayName
        self.stage = stage
        self.datingMethod = datingMethod
        self.dueDate = dueDate
        self.lastPeriodDate = lastPeriodDate
        self.privacyAcknowledgedAt = privacyAcknowledgedAt
        self.completedAt = completedAt
    }

    public var estimatedDueDate: Date? {
        switch datingMethod {
        case .dueDate:
            return dueDate
        case .lastPeriod:
            guard let lastPeriodDate else { return nil }
            return Calendar.autoupdatingCurrent.date(byAdding: .day, value: 280, to: lastPeriodDate)
        case .notSet:
            return nil
        }
    }

    public var gestationalWeek: Int? {
        guard stage == .pregnant else { return nil }

        let calendar = Calendar.autoupdatingCurrent
        let firstDay: Date?
        switch datingMethod {
        case .lastPeriod:
            firstDay = lastPeriodDate
        case .dueDate:
            firstDay = estimatedDueDate.flatMap {
                calendar.date(byAdding: .day, value: -280, to: $0)
            }
        case .notSet:
            firstDay = nil
        }

        guard let firstDay else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: firstDay),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        guard days >= 0 else { return 0 }
        return min(days / 7, 42)
    }

    public var dateSummary: String {
        guard let estimatedDueDate else { return "Pregnancy dates are not set" }
        let date = estimatedDueDate.formatted(date: .long, time: .omitted)
        return datingMethod == .dueDate ? "Due date: \(date)" : "Estimated due date: \(date)"
    }

    public var stageSummary: String {
        if let gestationalWeek {
            return "Week \(gestationalWeek) · \(stage.title)"
        }
        return stage.title
    }
}

public struct OnboardingDraft {
    public var displayName: String
    public var stage: OnboardingStage?
    public var datingMethod: PregnancyDatingMethod
    public var dueDate: Date?
    public var lastPeriodDate: Date?
    public var acceptedPrivacy: Bool

    public init(profile: OnboardingProfile? = nil) {
        displayName = profile?.displayName ?? ""
        stage = profile?.stage
        datingMethod = profile?.datingMethod ?? .notSet
        dueDate = profile?.dueDate
        lastPeriodDate = profile?.lastPeriodDate
        acceptedPrivacy = profile != nil
    }

    public var resolvedDueDate: Date? {
        switch datingMethod {
        case .dueDate:
            return dueDate
        case .lastPeriod:
            guard let lastPeriodDate else { return nil }
            return Calendar.autoupdatingCurrent.date(byAdding: .day, value: 280, to: lastPeriodDate)
        case .notSet:
            return nil
        }
    }

    public func makeProfile(now: Date = Date()) -> OnboardingProfile? {
        guard let stage, acceptedPrivacy else { return nil }
        return OnboardingProfile(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            stage: stage,
            datingMethod: datingMethod,
            dueDate: datingMethod == .dueDate ? dueDate : nil,
            lastPeriodDate: datingMethod == .lastPeriod ? lastPeriodDate : nil,
            privacyAcknowledgedAt: now,
            completedAt: now
        )
    }
}
