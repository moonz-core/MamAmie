import SwiftUI

struct OnboardingDatesView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var datePickerTarget: DatePickerTarget?
    @State private var datePickerInitialDate = Date()

    private var requiresDate: Bool {
        draft.stage == .pregnant && draft.datingMethod != .notSet
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Add pregnancy dates")
                    .font(.largeTitle.bold())
                Text("Reliable dates let MamAmie show an estimated week. You can skip this and add them later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if draft.stage == .pregnant {
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
            } else {
                OnboardingCard {
                    Label("Pregnancy dates are optional", systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundStyle(Color("AccentColor"))
                    Text("You can use MamAmie for planning or postpartum support without entering a due date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                title: requiresDate ? "Continue" : "Continue without dates",
                systemImage: "arrow.right",
                isDisabled: requiresDate && selectedDate == nil,
                action: onContinue
            )
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
                }
            }
        }
    }

    private var selectedDate: Date? {
        switch draft.datingMethod {
        case .dueDate: return draft.dueDate
        case .lastPeriod: return draft.lastPeriodDate
        case .notSet: return nil
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
                    .foregroundStyle(isSelected ? Color("AccentColor") : .tertiary)
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueDate: return "Due date"
        case .lastPeriod: return "First day of last period"
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
