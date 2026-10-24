import SwiftUI

// MARK: - Screen 1: About You
struct OnboardingScreen1AboutYouView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var showDatePicker = false

    private let commonCountries = [
        "United States", "United Kingdom", "Canada", "Australia", "India", "France", "Germany", "Other"
    ]

    private let languages = [
        "English", "Spanish", "French", "German", "Hindi", "Other"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 1: Name
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 8) {
                            OnboardingSectionHeader(
                                title: "What should we call you?",
                                subtitle: "Choose a name or nickname for personalized greetings.",
                                isOptional: true
                            )

                            TextField("Your name or nickname", text: $draft.displayName)
                                .textContentType(.givenName)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        }
                    }

                    // Question 2: Date of Birth & Age
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                title: "Date of birth",
                                subtitle: "Used only to calculate your age for health context.",
                                isOptional: true
                            )

                            HStack {
                                DatePicker(
                                    "Date of birth",
                                    selection: Binding(
                                        get: { draft.dateOfBirth ?? defaultBirthDate },
                                        set: { draft.dateOfBirth = $0 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()

                                Spacer()

                                if let age = draft.calculatedAge {
                                    Text("\(age) years old")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color("AccentColor"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color("AccentColor").opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                if draft.dateOfBirth != nil {
                                    Button {
                                        draft.dateOfBirth = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Question 3: Country
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                title: "Country of residence",
                                subtitle: "Helps tailor clinical guidelines and measurements.",
                                isOptional: true
                            )

                            FlowLayout(spacing: 8) {
                                ForEach(commonCountries, id: \.self) { c in
                                    OnboardingChip(
                                        title: c,
                                        isSelected: draft.country == c
                                    ) {
                                        draft.country = (draft.country == c ? "" : c)
                                    }
                                }
                            }

                            if draft.country == "Other" {
                                TextField("Enter your country", text: $draft.country)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    // Question 4: Preferred Language
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                title: "Preferred language",
                                subtitle: "Select your preferred language for advice and articles.",
                                isOptional: true
                            )

                            FlowLayout(spacing: 8) {
                                ForEach(languages, id: \.self) { lang in
                                    OnboardingChip(
                                        title: lang,
                                        isSelected: draft.preferredLanguage == lang
                                    ) {
                                        draft.preferredLanguage = lang
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
            Text("About You")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Let’s start with a few basic details to set up your personal space. Everything is optional.")
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

    private var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date()
    }
}

// MARK: - Screen 2: Your Pregnancy Journey
struct OnboardingScreen2JourneyView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var datePickerTarget: DatePickerTarget?
    @State private var datePickerInitialDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 5: Journey Stage
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CURRENT STAGE")
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(Color("AccentColor"))

                        ForEach(OnboardingStage.allCases) { stage in
                            OnboardingSelectableCard(
                                title: stage.title,
                                subtitle: stage.subtitle,
                                icon: stage.iconName,
                                isSelected: draft.stage == stage
                            ) {
                                draft.stage = stage
                            }
                        }
                    }

                    // Question 6 & 7: Conditional Dates / Cycle
                    if let stage = draft.stage {
                        stageSpecificCard(stage)
                    }

                    // Question 8: Clinical Care Provider
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                title: "Are you currently receiving care?",
                                subtitle: "Clinical care is vital for healthy outcomes. Select your care status.",
                                isOptional: true
                            )

                            VStack(spacing: 8) {
                                ForEach([
                                    ClinicalCareStatus.regularOBGYN,
                                    ClinicalCareStatus.midwifeOrFamily,
                                    ClinicalCareStatus.lookingForCare,
                                    ClinicalCareStatus.notReceivingCare
                                ]) { status in
                                    OnboardingSelectableCard(
                                        title: status.title,
                                        isSelected: draft.clinicalCareStatus == status
                                    ) {
                                        draft.clinicalCareStatus = status
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
        .sheet(item: $datePickerTarget) { target in
            DatePickerSheet(
                title: target.title,
                initialDate: datePickerInitialDate,
                range: target.range
            ) { date in
                switch target {
                case .dueDate: draft.dueDate = date
                case .lastPeriod: draft.lastPeriodDate = date
                case .childbirthDate: draft.childbirthDate = date
                }
            }
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
            Text("Your Journey")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Tell us where you are on your maternal journey so we can tailor weekly guidance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func stageSpecificCard(_ stage: OnboardingStage) -> some View {
        OnboardingCard {
            VStack(alignment: .leading, spacing: 12) {
                switch stage {
                case .pregnant:
                    OnboardingSectionHeader(
                        title: "Pregnancy timeline",
                        subtitle: "Estimated dates let MamAmie calculate your gestational week.",
                        isOptional: true
                    )

                    VStack(spacing: 10) {
                        ForEach(PregnancyDatingMethod.allCases) { method in
                            Button {
                                draft.datingMethod = method
                                if method != .dueDate { draft.dueDate = nil }
                                if method != .lastPeriod { draft.lastPeriodDate = nil }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: draft.datingMethod == method ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(draft.datingMethod == method ? Color("AccentColor") : Color(.tertiaryLabel))
                                    Text(method.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }

                        if draft.datingMethod == .dueDate {
                            DateSelectionRow(
                                title: "Due date",
                                value: draft.dueDate,
                                action: { presentPicker(.dueDate, currentDate: draft.dueDate) }
                            )
                        } else if draft.datingMethod == .lastPeriod {
                            DateSelectionRow(
                                title: "First day of last period",
                                value: draft.lastPeriodDate,
                                action: { presentPicker(.lastPeriod, currentDate: draft.lastPeriodDate) }
                            )
                        }
                    }

                case .planning:
                    OnboardingSectionHeader(
                        title: "Menstrual cycle tracking",
                        subtitle: "Would you like to track your cycles in MamAmie to identify fertile windows?",
                        isOptional: true
                    )

                    HStack(spacing: 10) {
                        OnboardingChip(
                            title: "Yes, track my cycle",
                            icon: "calendar.badge.clock",
                            isSelected: draft.trackCycle
                        ) {
                            draft.trackCycle = true
                        }

                        OnboardingChip(
                            title: "Not right now",
                            icon: "sparkles",
                            isSelected: !draft.trackCycle
                        ) {
                            draft.trackCycle = false
                        }
                    }

                case .postpartum:
                    OnboardingSectionHeader(
                        title: "Date of childbirth",
                        subtitle: "Helps tailor postpartum recovery milestones and baby care prompts.",
                        isOptional: true
                    )

                    DateSelectionRow(
                        title: "Date of birth",
                        value: draft.childbirthDate,
                        action: { presentPicker(.childbirthDate, currentDate: draft.childbirthDate) }
                    )
                }
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: draft.stage == nil,
                action: onContinue
            )

            if draft.stage != nil {
                OnboardingSkipButton(title: "Skip dates & continue", action: onSkip)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private func presentPicker(_ target: DatePickerTarget, currentDate: Date?) {
        datePickerInitialDate = currentDate ?? target.defaultDate
        datePickerTarget = target
    }
}

// MARK: - DatePicker Helper
private enum DatePickerTarget: String, Identifiable {
    case dueDate
    case lastPeriod
    case childbirthDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueDate: return "Due date"
        case .lastPeriod: return "First day of last period"
        case .childbirthDate: return "Date of childbirth"
        }
    }

    var defaultDate: Date { Date() }

    var range: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch self {
        case .dueDate:
            let earliest = calendar.date(byAdding: .day, value: -42, to: today) ?? today
            let latest = calendar.date(byAdding: .day, value: 320, to: today) ?? today
            return earliest...latest
        case .lastPeriod:
            let earliest = calendar.date(byAdding: .day, value: -320, to: today) ?? today
            return earliest...today
        case .childbirthDate:
            let earliest = calendar.date(byAdding: .year, value: -2, to: today) ?? today
            return earliest...today
        }
    }
}

private struct DatePickerSheet: View {
    let title: String
    let initialDate: Date
    let range: ClosedRange<Date>
    let onSave: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    init(title: String, initialDate: Date, range: ClosedRange<Date>, onSave: @escaping (Date) -> Void) {
        self.title = title
        self.initialDate = initialDate
        self.range = range
        self.onSave = onSave
        _selectedDate = State(initialValue: min(max(initialDate, range.lowerBound), range.upperBound))
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(title, selection: $selectedDate, in: range, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
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
