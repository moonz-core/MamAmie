import HealthKit
import SwiftUI

// MARK: - Screen 4: Your Health
struct OnboardingScreen4HealthView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    private let conditionChips = [
        "None", "Gestational diabetes", "Thyroid condition", "Asthma", "High blood pressure", "PCOS", "Type 1 / 2 diabetes", "Autoimmune condition"
    ]

    private let allergyChips = [
        "None", "Penicillin / Antibiotics", "Peanuts & Tree nuts", "Lactose / Dairy", "Gluten", "Latex", "Sulfa drugs", "Iodine"
    ]

    private let medicationChips = [
        "Prenatal multivitamin", "Folic acid", "Iron supplement", "Calcium / Vitamin D", "Prescription medication", "None"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 14: Existing medical conditions
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 14,
                                title: "Existing medical conditions",
                                subtitle: "Select any that apply to help personalize health insights.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(14),
                                onSkip: { draft.toggleSkipQuestion(14) }
                            )

                            if !draft.skippedQuestions.contains(14) {
                                FlowLayout(spacing: 8) {
                                    ForEach(conditionChips, id: \.self) { item in
                                        OnboardingChip(
                                            title: item,
                                            isSelected: isSelected(item, in: draft.medicalConditions)
                                        ) {
                                            toggleItem(item, in: &draft.medicalConditions)
                                        }
                                    }
                                }

                                TextField("Other medical condition (optional)", text: $draft.medicalConditionsNotes)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    // Question 15: Known allergies
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 15,
                                title: "Known allergies",
                                subtitle: "Helps us screen food suggestions and wellness tips.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(15),
                                onSkip: { draft.toggleSkipQuestion(15) }
                            )

                            if !draft.skippedQuestions.contains(15) {
                                FlowLayout(spacing: 8) {
                                    ForEach(allergyChips, id: \.self) { item in
                                        OnboardingChip(
                                            title: item,
                                            isSelected: isSelected(item, in: draft.allergies)
                                        ) {
                                            toggleItem(item, in: &draft.allergies)
                                        }
                                    }
                                }

                                TextField("Other allergy (optional)", text: $draft.allergiesNotes)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    // Question 16: Medications & supplements
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 16,
                                title: "Current medicines or supplements",
                                subtitle: "Keep track of supplements and vitamins you take daily.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(16),
                                onSkip: { draft.toggleSkipQuestion(16) }
                            )

                            if !draft.skippedQuestions.contains(16) {
                                FlowLayout(spacing: 8) {
                                    ForEach(medicationChips, id: \.self) { item in
                                        OnboardingChip(
                                            title: item,
                                            isSelected: isSelected(item, in: draft.medicationsAndSupplements)
                                        ) {
                                            toggleItem(item, in: &draft.medicationsAndSupplements)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Question 17: Clinician-provided instructions
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 8) {
                            OnboardingSectionHeader(
                                questionNumber: 17,
                                title: "Clinician-provided instructions",
                                subtitle: "Special precautions or advice given by your healthcare provider.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(17),
                                onSkip: { draft.toggleSkipQuestion(17) }
                            )

                            if !draft.skippedQuestions.contains(17) {
                                TextField("e.g. Daily iron supplement, monitor resting heart rate (optional)", text: $draft.clinicalInstructions, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    // Safety boundary card
                    OnboardingCard {
                        HStack(spacing: 10) {
                            Image(systemName: "hand.raised.shield")
                                .foregroundStyle(Color("AccentColor"))
                            Text("MamAmie stores your health answers privately on this device. We do not diagnose conditions or automatically classify pregnancies as high-risk.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            footerActions
        }
    }

    private var headerBar: some View {
        HStack {
            OnboardingBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Health")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Recording your health history helps MamAmie deliver thoughtful, relevant wellness insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )

            OnboardingSkipButton(title: "Skip this section", action: onSkip)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private func isSelected(_ item: String, in set: Set<String>) -> Bool {
        set.contains(item)
    }

    private func toggleItem(_ item: String, in set: inout Set<String>) {
        if item == "None" {
            set = ["None"]
            return
        }
        set.remove("None")
        if set.contains(item) { set.remove(item) }
        else { set.insert(item) }
    }
}

// MARK: - Screen 5: Nutrition and Lifestyle
struct OnboardingScreen5NutritionView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    private let lifestyleOptions = [
        "Hydration tracking", "Sleep monitoring", "Activity & step counting", "Mindful rest & breathing"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 18: Dietary preference
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 18,
                                title: "Dietary preference",
                                subtitle: "Tailors meal analysis and food diary insights.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(18),
                                onSkip: { draft.toggleSkipQuestion(18) }
                            )

                            if !draft.skippedQuestions.contains(18) {
                                VStack(spacing: 8) {
                                    ForEach(DietaryPreference.allCases) { diet in
                                        OnboardingSelectableCard(
                                            title: diet.title,
                                            subtitle: diet.subtitle,
                                            icon: diet.iconName,
                                            isSelected: draft.dietaryPreference == diet
                                        ) {
                                            draft.dietaryPreference = diet
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Question 19: Food allergies or dietary restrictions
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 8) {
                            OnboardingSectionHeader(
                                questionNumber: 19,
                                title: "Specific dietary restrictions",
                                subtitle: "e.g. Halal, Kosher, Nut-free, Low-sodium, No raw fish.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(19),
                                onSkip: { draft.toggleSkipQuestion(19) }
                            )

                            if !draft.skippedQuestions.contains(19) {
                                TextField("Enter any restrictions (optional)", text: $draft.dietaryRestrictionsNotes)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    // Question 20: Meal tracking preference
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 20,
                                title: "Meal tracking method",
                                subtitle: "Choose how you prefer to log food in MamAmie.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(20),
                                onSkip: { draft.toggleSkipQuestion(20) }
                            )

                            if !draft.skippedQuestions.contains(20) {
                                VStack(spacing: 8) {
                                    ForEach(MealTrackingPreference.allCases) { pref in
                                        OnboardingSelectableCard(
                                            title: pref.title,
                                            isSelected: draft.mealTrackingPreference == pref
                                        ) {
                                            draft.mealTrackingPreference = pref
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Question 21: Lifestyle tracking priorities
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 21,
                                title: "Wellness tracking priorities",
                                subtitle: "Which daily habits would you like to track on your home screen?",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(21),
                                onSkip: { draft.toggleSkipQuestion(21) }
                            )

                            if !draft.skippedQuestions.contains(21) {
                                FlowLayout(spacing: 8) {
                                    ForEach(lifestyleOptions, id: \.self) { opt in
                                        OnboardingChip(
                                            title: opt,
                                            isSelected: draft.lifestyleTrackingPriorities.contains(opt)
                                        ) {
                                            if draft.lifestyleTrackingPriorities.contains(opt) {
                                                draft.lifestyleTrackingPriorities.remove(opt)
                                            } else {
                                                draft.lifestyleTrackingPriorities.insert(opt)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            footerActions
        }
    }

    private var headerBar: some View {
        HStack {
            OnboardingBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nutrition & Lifestyle")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Personalize food scanning, nutrient goals, and daily wellness habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )

            OnboardingSkipButton(title: "Skip this section", action: onSkip)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Screen 6: Connected Health
struct OnboardingScreen6ConnectedHealthView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var isConnecting = false

    private let deviceOptions = [
        "Apple Watch", "Other Smartwatch", "Fitness Tracker", "Blood Pressure Monitor", "Smart Scale", "None / iPhone only"
    ]

    private let metricInterests = [
        "Heart rate", "Blood oxygen (SpO2)", "Blood pressure", "Sleep stages", "Activity & steps", "Heart-rate variability (HRV)", "Wrist temperature trends"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 22: Connected devices used
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 22,
                                title: "Do you use a health tracker or wearable?",
                                subtitle: "Select compatible devices you currently own.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(22),
                                onSkip: { draft.toggleSkipQuestion(22) }
                            )

                            if !draft.skippedQuestions.contains(22) {
                                FlowLayout(spacing: 8) {
                                    ForEach(deviceOptions, id: \.self) { dev in
                                        OnboardingChip(
                                            title: dev,
                                            isSelected: draft.connectedDevices.contains(dev)
                                        ) {
                                            toggleDevice(dev)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Question 23: Apple Health connection
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            OnboardingSectionHeader(
                                questionNumber: 23,
                                title: "Connect Apple Health",
                                subtitle: "Read-only access for vitals, sleep, and steps.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(23),
                                onSkip: { draft.toggleSkipQuestion(23) }
                            )

                            if !draft.skippedQuestions.contains(23) {
                                HStack(spacing: 12) {
                                    Image(systemName: "applewatch.radiowaves.left.and.right")
                                        .font(.title2)
                                        .foregroundStyle(Color("AccentColor"))
                                        .frame(width: 44, height: 44)
                                        .background(Color("AccentColor").opacity(0.12))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Apple Health Integration")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Read-only access for vitals, sleep, and steps.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if draft.connectedAppleHealth {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Apple Health Connected")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.primary)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Button {
                                        connectHealthKit()
                                    } label: {
                                        HStack(spacing: 8) {
                                            if isConnecting {
                                                ProgressView().tint(.white)
                                            } else {
                                                Image(systemName: "heart.fill")
                                            }
                                            Text(isConnecting ? "Connecting…" : "Connect Apple Health")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color("AccentColor"))
                                    .disabled(isConnecting)
                                }
                            }
                        }
                    }

                    // Question 24: Measurements of interest
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 24,
                                title: "Measurements of interest",
                                subtitle: "Which health indicators are you most interested in following?",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(24),
                                onSkip: { draft.toggleSkipQuestion(24) }
                            )

                            if !draft.skippedQuestions.contains(24) {
                                FlowLayout(spacing: 8) {
                                    ForEach(metricInterests, id: \.self) { metric in
                                        OnboardingChip(
                                            title: metric,
                                            isSelected: draft.measurementsOfInterest.contains(metric)
                                        ) {
                                            if draft.measurementsOfInterest.contains(metric) {
                                                draft.measurementsOfInterest.remove(metric)
                                            } else {
                                                draft.measurementsOfInterest.insert(metric)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Clinical boundary disclosure
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Wearable Measurement Notice", systemImage: "info.circle")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                            Text("Not every device supports every metric. Wearable readings provide wellness context and cannot establish clinical maternal or fetal wellbeing.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            footerActions
        }
    }

    private var headerBar: some View {
        HStack {
            OnboardingBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Connected Health")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Connect your Apple Watch or compatible trackers to view heart rate and rest trends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )

            OnboardingSkipButton(title: "Maybe later", action: onSkip)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private func toggleDevice(_ dev: String) {
        if dev.contains("None") {
            draft.connectedDevices = ["None / iPhone only"]
            return
        }
        draft.connectedDevices.remove("None / iPhone only")
        if draft.connectedDevices.contains(dev) { draft.connectedDevices.remove(dev) }
        else { draft.connectedDevices.insert(dev) }
    }

    private func connectHealthKit() {
        isConnecting = true
        Task {
            let service = HealthKitService()
            do {
                let success = try await service.requestAuthorization()
                await MainActor.run {
                    isConnecting = false
                    draft.connectedAppleHealth = success
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    draft.connectedAppleHealth = false
                }
            }
        }
    }
}

// MARK: - Screen 7: Care and Reminders
struct OnboardingScreen7RemindersView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 25: Reminders Multi-select
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            OnboardingSectionHeader(
                                questionNumber: 25,
                                title: "Reminders & care updates",
                                subtitle: "Choose which notifications and weekly summaries you'd like to receive.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(25),
                                onSkip: { draft.toggleSkipQuestion(25) }
                            )

                            if !draft.skippedQuestions.contains(25) {
                                VStack(spacing: 10) {
                                    ForEach(OnboardingReminderType.allCases) { reminder in
                                        OnboardingMultiSelectCard(
                                            title: reminder.title,
                                            subtitle: reminder.subtitle,
                                            icon: reminder.iconName,
                                            isSelected: draft.selectedReminders.contains(reminder)
                                        ) {
                                            if draft.selectedReminders.contains(reminder) {
                                                draft.selectedReminders.remove(reminder)
                                            } else {
                                                draft.selectedReminders.insert(reminder)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Safety disclosure for medication schedules
                    OnboardingCard {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.shield")
                                .foregroundStyle(Color("AccentColor"))
                            Text("Medication reminders must use schedules entered or confirmed by you, never AI-generated prescriptions.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            footerActions
        }
    }

    private var headerBar: some View {
        HStack {
            OnboardingBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Care & Reminders")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Choose which reminders and weekly summaries you’d like to receive. All reminders are optional.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Review Setup",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )

            OnboardingSkipButton(title: "Skip reminders for now", action: onSkip)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// FlowLayout helper
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                height += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
