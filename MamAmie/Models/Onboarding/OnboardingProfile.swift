import Foundation

public enum OnboardingStage: String, Codable, CaseIterable, Identifiable, Equatable {
    case planning
    case pregnant
    case postpartum

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .planning: return "Planning a pregnancy"
        case .pregnant: return "Currently pregnant"
        case .postpartum: return "Postpartum"
        }
    }

    public var subtitle: String {
        switch self {
        case .planning: return "Preparation, cycle awareness, and mindful wellness."
        case .pregnant: return "A calm place to follow your pregnancy week by week."
        case .postpartum: return "Gentle support for your recovery and newborn care."
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

public enum DietaryPreference: String, Codable, CaseIterable, Identifiable, Equatable {
    case vegetarian
    case vegan
    case eggetarian
    case nonVegetarian
    case otherOrNone

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .eggetarian: return "Eggetarian"
        case .nonVegetarian: return "Non-vegetarian"
        case .otherOrNone: return "Other / No specific preference"
        }
    }

    public var subtitle: String {
        switch self {
        case .vegetarian: return "Plant-based diet with dairy, no meat or seafood."
        case .vegan: return "100% plant-based, no animal products or dairy."
        case .eggetarian: return "Vegetarian with eggs included."
        case .nonVegetarian: return "Includes poultry, meat, and seafood."
        case .otherOrNone: return "Flexible eating or custom dietary lifestyle."
        }
    }

    public var iconName: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "laurel.leading"
        case .eggetarian: return "oval.portrait.fill"
        case .nonVegetarian: return "fork.knife"
        case .otherOrNone: return "heart.text.square"
        }
    }
}

public enum OnboardingReminderType: String, Codable, CaseIterable, Identifiable, Equatable {
    case pregnancyUpdates
    case appointments
    case medications
    case dailyCheckIns
    case weeklySummaries

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .pregnancyUpdates: return "Pregnancy updates"
        case .appointments: return "Appointments"
        case .medications: return "Medicine & supplement reminders"
        case .dailyCheckIns: return "Daily wellbeing check-ins"
        case .weeklySummaries: return "Weekly health summaries"
        }
    }

    public var subtitle: String {
        switch self {
        case .pregnancyUpdates: return "Weekly developmental insights and stage tips."
        case .appointments: return "Stay on top of prenatal visits, ultrasounds, and lab tests."
        case .medications: return "Timely reminders for schedules you enter or confirm."
        case .dailyCheckIns: return "Gentle hydration, rest, and mindful check-in prompts."
        case .weeklySummaries: return "Clear summaries of resting vitals, rest, and activity trends."
        }
    }

    public var iconName: String {
        switch self {
        case .pregnancyUpdates: return "bell.badge.fill"
        case .appointments: return "calendar.badge.clock"
        case .medications: return "pills.fill"
        case .dailyCheckIns: return "sun.max.fill"
        case .weeklySummaries: return "chart.bar.doc.horizontal.fill"
        }
    }
}

public struct OnboardingProfile: Codable, Equatable {
    public let displayName: String
    public let stage: OnboardingStage
    public let datingMethod: PregnancyDatingMethod
    public let dueDate: Date?
    public let lastPeriodDate: Date?
    public let trackCycle: Bool
    public let childbirthDate: Date?
    public let healthConditionsAndAllergies: String
    public let dietaryPreference: DietaryPreference?
    public let connectedAppleHealth: Bool
    public let selectedReminders: [OnboardingReminderType]
    public let privacyAcknowledgedAt: Date
    public let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case displayName
        case stage
        case datingMethod
        case dueDate
        case lastPeriodDate
        case trackCycle
        case childbirthDate
        case healthConditionsAndAllergies
        case dietaryPreference
        case connectedAppleHealth
        case selectedReminders
        case privacyAcknowledgedAt
        case completedAt
    }

    public init(
        displayName: String,
        stage: OnboardingStage,
        datingMethod: PregnancyDatingMethod = .notSet,
        dueDate: Date? = nil,
        lastPeriodDate: Date? = nil,
        trackCycle: Bool = false,
        childbirthDate: Date? = nil,
        healthConditionsAndAllergies: String = "",
        dietaryPreference: DietaryPreference? = nil,
        connectedAppleHealth: Bool = false,
        selectedReminders: [OnboardingReminderType] = [],
        privacyAcknowledgedAt: Date = Date(),
        completedAt: Date = Date()
    ) {
        self.displayName = displayName
        self.stage = stage
        self.datingMethod = datingMethod
        self.dueDate = dueDate
        self.lastPeriodDate = lastPeriodDate
        self.trackCycle = trackCycle
        self.childbirthDate = childbirthDate
        self.healthConditionsAndAllergies = healthConditionsAndAllergies
        self.dietaryPreference = dietaryPreference
        self.connectedAppleHealth = connectedAppleHealth
        self.selectedReminders = selectedReminders
        self.privacyAcknowledgedAt = privacyAcknowledgedAt
        self.completedAt = completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = (try? container.decode(String.self, forKey: .displayName)) ?? ""
        stage = (try? container.decode(OnboardingStage.self, forKey: .stage)) ?? .pregnant
        datingMethod = (try? container.decode(PregnancyDatingMethod.self, forKey: .datingMethod)) ?? .notSet
        dueDate = try? container.decodeIfPresent(Date.self, forKey: .dueDate)
        lastPeriodDate = try? container.decodeIfPresent(Date.self, forKey: .lastPeriodDate)
        trackCycle = (try? container.decodeIfPresent(Bool.self, forKey: .trackCycle)) ?? false
        childbirthDate = try? container.decodeIfPresent(Date.self, forKey: .childbirthDate)
        healthConditionsAndAllergies = (try? container.decodeIfPresent(String.self, forKey: .healthConditionsAndAllergies)) ?? ""
        dietaryPreference = try? container.decodeIfPresent(DietaryPreference.self, forKey: .dietaryPreference)
        connectedAppleHealth = (try? container.decodeIfPresent(Bool.self, forKey: .connectedAppleHealth)) ?? false
        selectedReminders = (try? container.decodeIfPresent([OnboardingReminderType].self, forKey: .selectedReminders)) ?? []
        privacyAcknowledgedAt = (try? container.decodeIfPresent(Date.self, forKey: .privacyAcknowledgedAt)) ?? Date()
        completedAt = (try? container.decodeIfPresent(Date.self, forKey: .completedAt)) ?? Date()
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
        switch stage {
        case .pregnant:
            guard let estimatedDueDate else { return "Pregnancy dates not set (skip)" }
            let date = estimatedDueDate.formatted(date: .long, time: .omitted)
            return datingMethod == .dueDate ? "Due date: \(date)" : "Estimated due date: \(date)"
        case .planning:
            return trackCycle ? "Menstrual cycle tracking enabled" : "Cycle tracking optional"
        case .postpartum:
            if let childbirthDate {
                return "Date of childbirth: \(childbirthDate.formatted(date: .long, time: .omitted))"
            }
            return "Postpartum recovery"
        }
    }

    public var stageSummary: String {
        if stage == .pregnant, let gestationalWeek {
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
    public var trackCycle: Bool
    public var childbirthDate: Date?
    public var healthConditionsAndAllergies: String
    public var dietaryPreference: DietaryPreference?
    public var connectedAppleHealth: Bool
    public var selectedReminders: Set<OnboardingReminderType>
    public var acceptedPrivacy: Bool

    public init(profile: OnboardingProfile? = nil) {
        displayName = profile?.displayName ?? ""
        stage = profile?.stage
        datingMethod = profile?.datingMethod ?? .notSet
        dueDate = profile?.dueDate
        lastPeriodDate = profile?.lastPeriodDate
        trackCycle = profile?.trackCycle ?? true
        childbirthDate = profile?.childbirthDate
        healthConditionsAndAllergies = profile?.healthConditionsAndAllergies ?? ""
        dietaryPreference = profile?.dietaryPreference
        connectedAppleHealth = profile?.connectedAppleHealth ?? false
        selectedReminders = Set(profile?.selectedReminders ?? [
            .pregnancyUpdates,
            .appointments,
            .medications,
            .dailyCheckIns
        ])
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
            trackCycle: stage == .planning ? trackCycle : false,
            childbirthDate: stage == .postpartum ? childbirthDate : nil,
            healthConditionsAndAllergies: healthConditionsAndAllergies.trimmingCharacters(in: .whitespacesAndNewlines),
            dietaryPreference: dietaryPreference,
            connectedAppleHealth: connectedAppleHealth,
            selectedReminders: Array(selectedReminders),
            privacyAcknowledgedAt: now,
            completedAt: now
        )
    }
}
