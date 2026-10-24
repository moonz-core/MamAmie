import SwiftUI

struct OnboardingDatesView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var datePickerTarget: DatePickerTarget?
    @State private var datePickerInitialDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            switch draft.stage ?? .pregnant {
            case .pregnant:
                pregnantDatesSection
            case .planning:
                planningCycleSection
            case .postpartum:
                postpartumDatesSection
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: primaryButtonTitle,
                    systemImage: "arrow.right",
                    isDisabled: false,
                    action: onContinue
                )

                if shouldShowSkipButton {
                    OnboardingSkipButton(title: "Skip for now", action: onContinue)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .sheet(item: $datePickerTarget) { target in
            DatePickerSheet(
                title: target.title,
                initialDate: datePickerInitialDate,
                range: target.range
            ) { date in
                switch target {
                case .dueDate:
                    draft.dueDate = date
                case .lastPeriod:
                    draft.lastPeriodDate = date
                case .childbirthDate:
                    draft.childbirthDate = date
                }
            }
        }
    }

    // MARK: - Pregnant View
    private var pregnantDatesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pregnancy information")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))
                Text("An estimated due date or last period date helps MamAmie show gestational week progress. Skip if you're not sure.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(PregnancyDatingMethod.allCases) { method in
                    DatingMethodRow(
                        method: method,
                        isSelected: draft.datingMethod == method
                    ) {
                        select(method)
                    }
                }
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
    }

    // MARK: - Planning View
    private var planningCycleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Menstrual cycle tracking")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))
                Text("Would you like to track your menstrual cycle in MamAmie to help with pre-pregnancy preparation?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                OnboardingSelectableCard(
                    title: "Yes, track my cycle",
                    subtitle: "Log your periods, fertile windows, and cycle patterns in the calendar.",
                    icon: "calendar.badge.clock",
                    isSelected: draft.trackCycle
                ) {
                    draft.trackCycle = true
                }

                OnboardingSelectableCard(
                    title: "Not right now / Maybe later",
                    subtitle: "Focus on general pre-pregnancy wellness without cycle logs. You can enable this anytime.",
                    icon: "sparkles",
                    isSelected: !draft.trackCycle
                ) {
                    draft.trackCycle = false
                }
            }
        }
    }

    // MARK: - Postpartum View
    private var postpartumDatesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Postpartum recovery")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))
                Text("Entering your date of childbirth helps us tailor your postpartum recovery weeks. Skip if you prefer.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DateSelectionRow(
                title: "Date of childbirth",
                value: draft.childbirthDate,
                action: { presentPicker(.childbirthDate, currentDate: draft.childbirthDate) }
            )

            if draft.childbirthDate != nil {
                Button {
                    draft.childbirthDate = nil
                } label: {
                    Text("Clear date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var primaryButtonTitle: String {
        switch draft.stage ?? .pregnant {
        case .pregnant:
            if draft.datingMethod == .notSet {
                return "Continue without dates"
            }
            return "Continue"
        case .planning:
            return "Continue"
        case .postpartum:
            return draft.childbirthDate == nil ? "Continue without date" : "Continue"
        }
    }

    private var shouldShowSkipButton: Bool {
        switch draft.stage ?? .pregnant {
        case .pregnant:
            return draft.datingMethod != .notSet && draft.resolvedDueDate == nil
        case .planning:
            return false
        case .postpartum:
            return draft.childbirthDate == nil
        }
    }

    private func select(_ method: PregnancyDatingMethod) {
        draft.datingMethod = method
        if method != .dueDate { draft.dueDate = nil }
        if method != .lastPeriod { draft.lastPeriodDate = nil }
    }

    private func presentPicker(_ target: DatePickerTarget, currentDate: Date?) {
        datePickerInitialDate = currentDate ?? target.defaultDate
        datePickerTarget = target
    }
}

private struct DatingMethodRow: View {
    let method: PregnancyDatingMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color("AccentColor") : Color(.tertiaryLabel))
                VStack(alignment: .leading, spacing: 3) {
                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(method.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(14)
            .background(isSelected ? Color("AccentColor").opacity(0.09) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

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

    var defaultDate: Date {
        Date()
    }

    var range: ClosedRange<Date> {
        let calendar = Calendar.autoupdatingCurrent
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
