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

public enum ClinicalCareStatus: String, Codable, CaseIterable, Identifiable, Equatable {
    case regularOBGYN
    case midwifeOrFamily
    case lookingForCare
    case notReceivingCare
    case unspecified

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .regularOBGYN: return "Yes, regular OB/GYN care"
        case .midwifeOrFamily: return "Yes, midwife or family doctor"
        case .lookingForCare: return "Currently looking for care"
        case .notReceivingCare: return "Not receiving care right now"
        case .unspecified: return "Not specified"
        }
    }
}

public enum MultiplePregnancyType: String, Codable, CaseIterable, Identifiable, Equatable {
    case single
    case twins
    case multiples
    case unsure

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .single: return "Single baby"
        case .twins: return "Twins"
        case .multiples: return "Triplets or multiples (3+)"
        case .unsure: return "Not sure yet"
        }
    }
}

public enum MealTrackingPreference: String, Codable, CaseIterable, Identifiable, Equatable {
    case both
    case photo
    case manual
    case skip

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .both: return "Both photo & manual entry"
        case .photo: return "Photo scanning primarily"
        case .manual: return "Manual food diary"
        case .skip: return "Decide later"
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
    // Screen 1: About You
    public let displayName: String
    public let dateOfBirth: Date?
    public let country: String
    public let preferredLanguage: String

    // Screen 2: Pregnancy Journey
    public let stage: OnboardingStage
    public let datingMethod: PregnancyDatingMethod
    public let dueDate: Date?
    public let lastPeriodDate: Date?
    public let trackCycle: Bool
    public let childbirthDate: Date?
    public let clinicalCareStatus: ClinicalCareStatus

    // Screen 3: Pregnancy History
    public let isFirstPregnancy: Bool?
    public let totalPregnancies: Int?
    public let previousBirths: Int?
    public let multiplePregnancyType: MultiplePregnancyType
    public let previousComplicationsNotes: String

    // Screen 4: Your Health
    public let medicalConditions: [String]
    public let medicalConditionsNotes: String
    public let allergies: [String]
    public let allergiesNotes: String
    public let medicationsAndSupplements: [String]
    public let clinicalInstructions: String

    // Screen 5: Nutrition & Lifestyle
    public let dietaryPreference: DietaryPreference?
    public let dietaryRestrictionsNotes: String
    public let mealTrackingPreference: MealTrackingPreference
    public let lifestyleTrackingPriorities: [String]

    // Screen 6: Connected Health
    public let connectedDevices: [String]
    public let connectedAppleHealth: Bool
    public let measurementsOfInterest: [String]

    // Screen 7: Care & Reminders
    public let selectedReminders: [OnboardingReminderType]

    // Administrative
    public let privacyAcknowledgedAt: Date
    public let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case displayName, dateOfBirth, country, preferredLanguage
        case stage, datingMethod, dueDate, lastPeriodDate, trackCycle, childbirthDate, clinicalCareStatus
        case isFirstPregnancy, totalPregnancies, previousBirths, multiplePregnancyType, previousComplicationsNotes
        case medicalConditions, medicalConditionsNotes, allergies, allergiesNotes, medicationsAndSupplements, clinicalInstructions
        case dietaryPreference, dietaryRestrictionsNotes, mealTrackingPreference, lifestyleTrackingPriorities
        case connectedDevices, connectedAppleHealth, measurementsOfInterest
        case selectedReminders
        case privacyAcknowledgedAt, completedAt
        case healthConditionsAndAllergies // backwards compatibility key
    }

    public init(
        displayName: String,
        dateOfBirth: Date? = nil,
        country: String = "",
        preferredLanguage: String = "English",
        stage: OnboardingStage,
        datingMethod: PregnancyDatingMethod = .notSet,
        dueDate: Date? = nil,
        lastPeriodDate: Date? = nil,
        trackCycle: Bool = false,
        childbirthDate: Date? = nil,
        clinicalCareStatus: ClinicalCareStatus = .unspecified,
        isFirstPregnancy: Bool? = nil,
        totalPregnancies: Int? = nil,
        previousBirths: Int? = nil,
        multiplePregnancyType: MultiplePregnancyType = .single,
        previousComplicationsNotes: String = "",
        medicalConditions: [String] = [],
        medicalConditionsNotes: String = "",
        allergies: [String] = [],
        allergiesNotes: String = "",
        medicationsAndSupplements: [String] = [],
        clinicalInstructions: String = "",
        dietaryPreference: DietaryPreference? = nil,
        dietaryRestrictionsNotes: String = "",
        mealTrackingPreference: MealTrackingPreference = .both,
        lifestyleTrackingPriorities: [String] = [],
        connectedDevices: [String] = [],
        connectedAppleHealth: Bool = false,
        measurementsOfInterest: [String] = [],
        selectedReminders: [OnboardingReminderType] = [],
        privacyAcknowledgedAt: Date = Date(),
        completedAt: Date = Date()
    ) {
        self.displayName = displayName
        self.dateOfBirth = dateOfBirth
        self.country = country
        self.preferredLanguage = preferredLanguage
        self.stage = stage
        self.datingMethod = datingMethod
        self.dueDate = dueDate
        self.lastPeriodDate = lastPeriodDate
        self.trackCycle = trackCycle
        self.childbirthDate = childbirthDate
        self.clinicalCareStatus = clinicalCareStatus
        self.isFirstPregnancy = isFirstPregnancy
        self.totalPregnancies = totalPregnancies
        self.previousBirths = previousBirths
        self.multiplePregnancyType = multiplePregnancyType
        self.previousComplicationsNotes = previousComplicationsNotes
        self.medicalConditions = medicalConditions
        self.medicalConditionsNotes = medicalConditionsNotes
        self.allergies = allergies
        self.allergiesNotes = allergiesNotes
        self.medicationsAndSupplements = medicationsAndSupplements
        self.clinicalInstructions = clinicalInstructions
        self.dietaryPreference = dietaryPreference
        self.dietaryRestrictionsNotes = dietaryRestrictionsNotes
        self.mealTrackingPreference = mealTrackingPreference
        self.lifestyleTrackingPriorities = lifestyleTrackingPriorities
        self.connectedDevices = connectedDevices
        self.connectedAppleHealth = connectedAppleHealth
        self.measurementsOfInterest = measurementsOfInterest
        self.selectedReminders = selectedReminders
        self.privacyAcknowledgedAt = privacyAcknowledgedAt
        self.completedAt = completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = (try? container.decode(String.self, forKey: .displayName)) ?? ""
        dateOfBirth = try? container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        country = (try? container.decodeIfPresent(String.self, forKey: .country)) ?? ""
        preferredLanguage = (try? container.decodeIfPresent(String.self, forKey: .preferredLanguage)) ?? "English"

        stage = (try? container.decode(OnboardingStage.self, forKey: .stage)) ?? .pregnant
        datingMethod = (try? container.decode(PregnancyDatingMethod.self, forKey: .datingMethod)) ?? .notSet
        dueDate = try? container.decodeIfPresent(Date.self, forKey: .dueDate)
        lastPeriodDate = try? container.decodeIfPresent(Date.self, forKey: .lastPeriodDate)
        trackCycle = (try? container.decodeIfPresent(Bool.self, forKey: .trackCycle)) ?? false
        childbirthDate = try? container.decodeIfPresent(Date.self, forKey: .childbirthDate)
        clinicalCareStatus = (try? container.decodeIfPresent(ClinicalCareStatus.self, forKey: .clinicalCareStatus)) ?? .unspecified

        isFirstPregnancy = try? container.decodeIfPresent(Bool.self, forKey: .isFirstPregnancy)
        totalPregnancies = try? container.decodeIfPresent(Int.self, forKey: .totalPregnancies)
        previousBirths = try? container.decodeIfPresent(Int.self, forKey: .previousBirths)
        multiplePregnancyType = (try? container.decodeIfPresent(MultiplePregnancyType.self, forKey: .multiplePregnancyType)) ?? .single
        previousComplicationsNotes = (try? container.decodeIfPresent(String.self, forKey: .previousComplicationsNotes)) ?? ""

        let oldHealthNotes = (try? container.decodeIfPresent(String.self, forKey: .healthConditionsAndAllergies)) ?? ""
        medicalConditions = (try? container.decodeIfPresent([String].self, forKey: .medicalConditions)) ?? []
        medicalConditionsNotes = (try? container.decodeIfPresent(String.self, forKey: .medicalConditionsNotes)) ?? oldHealthNotes
        allergies = (try? container.decodeIfPresent([String].self, forKey: .allergies)) ?? []
        allergiesNotes = (try? container.decodeIfPresent(String.self, forKey: .allergiesNotes)) ?? ""
        medicationsAndSupplements = (try? container.decodeIfPresent([String].self, forKey: .medicationsAndSupplements)) ?? []
        clinicalInstructions = (try? container.decodeIfPresent(String.self, forKey: .clinicalInstructions)) ?? ""

        dietaryPreference = try? container.decodeIfPresent(DietaryPreference.self, forKey: .dietaryPreference)
        dietaryRestrictionsNotes = (try? container.decodeIfPresent(String.self, forKey: .dietaryRestrictionsNotes)) ?? ""
        mealTrackingPreference = (try? container.decodeIfPresent(MealTrackingPreference.self, forKey: .mealTrackingPreference)) ?? .both
        lifestyleTrackingPriorities = (try? container.decodeIfPresent([String].self, forKey: .lifestyleTrackingPriorities)) ?? []

        connectedDevices = (try? container.decodeIfPresent([String].self, forKey: .connectedDevices)) ?? []
        connectedAppleHealth = (try? container.decodeIfPresent(Bool.self, forKey: .connectedAppleHealth)) ?? false
        measurementsOfInterest = (try? container.decodeIfPresent([String].self, forKey: .measurementsOfInterest)) ?? []

        selectedReminders = (try? container.decodeIfPresent([OnboardingReminderType].self, forKey: .selectedReminders)) ?? []
        privacyAcknowledgedAt = (try? container.decodeIfPresent(Date.self, forKey: .privacyAcknowledgedAt)) ?? Date()
        completedAt = (try? container.decodeIfPresent(Date.self, forKey: .completedAt)) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(country, forKey: .country)
        try container.encode(preferredLanguage, forKey: .preferredLanguage)

        try container.encode(stage, forKey: .stage)
        try container.encode(datingMethod, forKey: .datingMethod)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(lastPeriodDate, forKey: .lastPeriodDate)
        try container.encode(trackCycle, forKey: .trackCycle)
        try container.encodeIfPresent(childbirthDate, forKey: .childbirthDate)
        try container.encode(clinicalCareStatus, forKey: .clinicalCareStatus)

        try container.encodeIfPresent(isFirstPregnancy, forKey: .isFirstPregnancy)
        try container.encodeIfPresent(totalPregnancies, forKey: .totalPregnancies)
        try container.encodeIfPresent(previousBirths, forKey: .previousBirths)
        try container.encode(multiplePregnancyType, forKey: .multiplePregnancyType)
        try container.encode(previousComplicationsNotes, forKey: .previousComplicationsNotes)

        try container.encode(medicalConditions, forKey: .medicalConditions)
        try container.encode(medicalConditionsNotes, forKey: .medicalConditionsNotes)
        try container.encode(allergies, forKey: .allergies)
        try container.encode(allergiesNotes, forKey: .allergiesNotes)
        try container.encode(medicationsAndSupplements, forKey: .medicationsAndSupplements)
        try container.encode(clinicalInstructions, forKey: .clinicalInstructions)

        try container.encodeIfPresent(dietaryPreference, forKey: .dietaryPreference)
        try container.encode(dietaryRestrictionsNotes, forKey: .dietaryRestrictionsNotes)
        try container.encode(mealTrackingPreference, forKey: .mealTrackingPreference)
        try container.encode(lifestyleTrackingPriorities, forKey: .lifestyleTrackingPriorities)

        try container.encode(connectedDevices, forKey: .connectedDevices)
        try container.encode(connectedAppleHealth, forKey: .connectedAppleHealth)
        try container.encode(measurementsOfInterest, forKey: .measurementsOfInterest)

        try container.encode(selectedReminders, forKey: .selectedReminders)
        try container.encode(privacyAcknowledgedAt, forKey: .privacyAcknowledgedAt)
        try container.encode(completedAt, forKey: .completedAt)
        try container.encode(healthConditionsAndAllergies, forKey: .healthConditionsAndAllergies)
    }

    public var age: Int? {
        guard let dateOfBirth else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year
    }

    public var healthConditionsAndAllergies: String {
        var items: [String] = []
        if !medicalConditions.isEmpty { items.append(medicalConditions.joined(separator: ", ")) }
        if !medicalConditionsNotes.isEmpty && !items.contains(medicalConditionsNotes) { items.append(medicalConditionsNotes) }
        if !allergies.isEmpty { items.append("Allergies: " + allergies.joined(separator: ", ")) }
        return items.joined(separator: " · ")
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

    public var stageDetailSummary: String {
        dateSummary
    }

    public var stageSummary: String {
        if stage == .pregnant, let gestationalWeek {
            return "Week \(gestationalWeek) · \(stage.title)"
        }
        return stage.title
    }
}

public struct OnboardingDraft {
    // Screen 1: About You
    public var displayName: String
    public var dateOfBirth: Date?
    public var country: String
    public var preferredLanguage: String

    // Screen 2: Pregnancy Journey
    public var stage: OnboardingStage?
    public var datingMethod: PregnancyDatingMethod
    public var dueDate: Date?
    public var lastPeriodDate: Date?
    public var trackCycle: Bool
    public var childbirthDate: Date?
    public var clinicalCareStatus: ClinicalCareStatus

    // Screen 3: Pregnancy History
    public var isFirstPregnancy: Bool?
    public var totalPregnancies: Int
    public var previousBirths: Int
    public var multiplePregnancyType: MultiplePregnancyType
    public var previousComplicationsNotes: String

    // Screen 4: Your Health
    public var medicalConditions: Set<String>
    public var medicalConditionsNotes: String
    public var allergies: Set<String>
    public var allergiesNotes: String
    public var medicationsAndSupplements: Set<String>
    public var clinicalInstructions: String

    // Screen 5: Nutrition & Lifestyle
    public var dietaryPreference: DietaryPreference?
    public var dietaryRestrictionsNotes: String
    public var mealTrackingPreference: MealTrackingPreference
    public var lifestyleTrackingPriorities: Set<String>

    // Screen 6: Connected Health
    public var connectedDevices: Set<String>
    public var connectedAppleHealth: Bool
    public var measurementsOfInterest: Set<String>

    // Screen 7: Care & Reminders
    public var selectedReminders: Set<OnboardingReminderType>
    public var acceptedPrivacy: Bool

    // Tracking individual skipped questions (Questions 1 to 25)
    public var skippedQuestions: Set<Int> = []

    public mutating func toggleSkipQuestion(_ number: Int) {
        if skippedQuestions.contains(number) {
            skippedQuestions.remove(number)
        } else {
            skippedQuestions.insert(number)
            switch number {
            case 1: displayName = ""
            case 2: dateOfBirth = nil
            case 3: country = ""
            case 4: preferredLanguage = "English"
            case 5: if stage == nil { stage = .pregnant }
            case 6: dueDate = nil; childbirthDate = nil; datingMethod = .notSet
            case 7: lastPeriodDate = nil; datingMethod = .notSet
            case 8: clinicalCareStatus = .unspecified
            case 9: isFirstPregnancy = nil
            case 10: totalPregnancies = 1
            case 11: previousBirths = 0
            case 12: multiplePregnancyType = .unsure
            case 13: previousComplicationsNotes = ""
            case 14: medicalConditions = ["None"]; medicalConditionsNotes = ""
            case 15: allergies = ["None"]; allergiesNotes = ""
            case 16: medicationsAndSupplements = ["None"]
            case 17: clinicalInstructions = ""
            case 18: dietaryPreference = nil
            case 19: dietaryRestrictionsNotes = ""
            case 20: mealTrackingPreference = .skip
            case 21: lifestyleTrackingPriorities = []
            case 22: connectedDevices = ["None / iPhone only"]
            case 23: connectedAppleHealth = false
            case 24: measurementsOfInterest = []
            case 25: selectedReminders = []
            default: break
            }
        }
    }

    public init(profile: OnboardingProfile? = nil) {
        displayName = profile?.displayName ?? ""
        dateOfBirth = profile?.dateOfBirth
        country = profile?.country ?? ""
        preferredLanguage = profile?.preferredLanguage ?? "English"

        stage = profile?.stage
        datingMethod = profile?.datingMethod ?? .notSet
        dueDate = profile?.dueDate
        lastPeriodDate = profile?.lastPeriodDate
        trackCycle = profile?.trackCycle ?? true
        childbirthDate = profile?.childbirthDate
        clinicalCareStatus = profile?.clinicalCareStatus ?? .unspecified

        isFirstPregnancy = profile?.isFirstPregnancy
        totalPregnancies = profile?.totalPregnancies ?? 1
        previousBirths = profile?.previousBirths ?? 0
        multiplePregnancyType = profile?.multiplePregnancyType ?? .single
        previousComplicationsNotes = profile?.previousComplicationsNotes ?? ""

        medicalConditions = Set(profile?.medicalConditions ?? [])
        medicalConditionsNotes = profile?.medicalConditionsNotes ?? ""
        allergies = Set(profile?.allergies ?? [])
        allergiesNotes = profile?.allergiesNotes ?? ""
        medicationsAndSupplements = Set(profile?.medicationsAndSupplements ?? [])
        clinicalInstructions = profile?.clinicalInstructions ?? ""

        dietaryPreference = profile?.dietaryPreference
        dietaryRestrictionsNotes = profile?.dietaryRestrictionsNotes ?? ""
        mealTrackingPreference = profile?.mealTrackingPreference ?? .both
        lifestyleTrackingPriorities = Set(profile?.lifestyleTrackingPriorities ?? ["Hydration", "Sleep", "Activity"])

        connectedDevices = Set(profile?.connectedDevices ?? [])
        connectedAppleHealth = profile?.connectedAppleHealth ?? false
        measurementsOfInterest = Set(profile?.measurementsOfInterest ?? ["Heart rate", "Sleep", "Activity"])

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

    public var calculatedAge: Int? {
        guard let dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
    }

    public func makeProfile(now: Date = Date()) -> OnboardingProfile? {
        guard let stage, acceptedPrivacy else { return nil }
        return OnboardingProfile(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth,
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            preferredLanguage: preferredLanguage,
            stage: stage,
            datingMethod: datingMethod,
            dueDate: datingMethod == .dueDate ? dueDate : nil,
            lastPeriodDate: datingMethod == .lastPeriod ? lastPeriodDate : nil,
            trackCycle: stage == .planning ? trackCycle : false,
            childbirthDate: stage == .postpartum ? childbirthDate : nil,
            clinicalCareStatus: clinicalCareStatus,
            isFirstPregnancy: isFirstPregnancy,
            totalPregnancies: totalPregnancies,
            previousBirths: previousBirths,
            multiplePregnancyType: multiplePregnancyType,
            previousComplicationsNotes: previousComplicationsNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            medicalConditions: Array(medicalConditions),
            medicalConditionsNotes: medicalConditionsNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            allergies: Array(allergies),
            allergiesNotes: allergiesNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            medicationsAndSupplements: Array(medicationsAndSupplements),
            clinicalInstructions: clinicalInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
            dietaryPreference: dietaryPreference,
            dietaryRestrictionsNotes: dietaryRestrictionsNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            mealTrackingPreference: mealTrackingPreference,
            lifestyleTrackingPriorities: Array(lifestyleTrackingPriorities),
            connectedDevices: Array(connectedDevices),
            connectedAppleHealth: connectedAppleHealth,
            measurementsOfInterest: Array(measurementsOfInterest),
            selectedReminders: Array(selectedReminders),
            privacyAcknowledgedAt: now,
            completedAt: now
        )
    }
}
