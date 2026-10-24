import SwiftUI

// MARK: - Screen 8: Review and Continue
struct OnboardingSummaryView: View {
    @Binding var draft: OnboardingDraft
    let onFinish: () -> Void
    let onBack: () -> Void
    var onEditStep: ((Int) -> Void)? = nil

    private var profile: OnboardingProfile? {
        draft.makeProfile()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Group 1: About You
                    SummaryGroupCard(title: "About You (Q1–Q4)", stepNumber: 1, onEdit: { onEditStep?(1) }) {
                        SummaryFieldRow(questionNumber: 1, label: "Name", value: draft.displayName.isEmpty ? nil : draft.displayName, isSkipped: draft.skippedQuestions.contains(1))
                        SummaryFieldRow(questionNumber: 2, label: "Age", value: draft.calculatedAge != nil ? "\(draft.calculatedAge!) years old" : nil, isSkipped: draft.skippedQuestions.contains(2))
                        SummaryFieldRow(questionNumber: 3, label: "Country", value: draft.country.isEmpty ? nil : draft.country, isSkipped: draft.skippedQuestions.contains(3))
                        SummaryFieldRow(questionNumber: 4, label: "Language", value: draft.preferredLanguage, isSkipped: draft.skippedQuestions.contains(4))
                    }

                    // Group 2: Your Journey
                    SummaryGroupCard(title: "Pregnancy Journey (Q5–Q8)", stepNumber: 2, onEdit: { onEditStep?(2) }) {
                        SummaryFieldRow(questionNumber: 5, label: "Stage", value: draft.stage?.title, isSkipped: draft.skippedQuestions.contains(5))
                        SummaryFieldRow(questionNumber: 6, label: "Due/Birth Date", value: profile?.dateSummary, isSkipped: draft.skippedQuestions.contains(6))
                        SummaryFieldRow(questionNumber: 7, label: "Last Period (LMP)", value: draft.lastPeriodDate?.formatted(date: .long, time: .omitted), isSkipped: draft.skippedQuestions.contains(7))
                        SummaryFieldRow(questionNumber: 8, label: "Clinical Care", value: draft.clinicalCareStatus != .unspecified ? draft.clinicalCareStatus.title : nil, isSkipped: draft.skippedQuestions.contains(8))
                    }

                    // Group 3: Pregnancy History
                    SummaryGroupCard(title: "Pregnancy History (Q9–Q13)", stepNumber: 3, onEdit: { onEditStep?(3) }) {
                        SummaryFieldRow(questionNumber: 9, label: "First pregnancy", value: draft.isFirstPregnancy == true ? "Yes" : (draft.isFirstPregnancy == false ? "No" : nil), isSkipped: draft.skippedQuestions.contains(9))
                        SummaryFieldRow(questionNumber: 10, label: "Total pregnancies", value: "\(draft.totalPregnancies)", isSkipped: draft.skippedQuestions.contains(10))
                        SummaryFieldRow(questionNumber: 11, label: "Previous births", value: "\(draft.previousBirths)", isSkipped: draft.skippedQuestions.contains(11))
                        SummaryFieldRow(questionNumber: 12, label: "Expecting", value: draft.multiplePregnancyType.title, isSkipped: draft.skippedQuestions.contains(12))
                        SummaryFieldRow(questionNumber: 13, label: "Complications", value: draft.previousComplicationsNotes.isEmpty ? nil : draft.previousComplicationsNotes, isSkipped: draft.skippedQuestions.contains(13))
                    }

                    // Group 4: Your Health
                    SummaryGroupCard(title: "Your Health (Q14–Q17)", stepNumber: 4, onEdit: { onEditStep?(4) }) {
                        SummaryFieldRow(
                            questionNumber: 14,
                            label: "Conditions",
                            value: draft.medicalConditions.isEmpty ? nil : draft.medicalConditions.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(14)
                        )
                        SummaryFieldRow(
                            questionNumber: 15,
                            label: "Allergies",
                            value: draft.allergies.isEmpty ? nil : draft.allergies.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(15)
                        )
                        SummaryFieldRow(
                            questionNumber: 16,
                            label: "Supplements",
                            value: draft.medicationsAndSupplements.isEmpty ? nil : draft.medicationsAndSupplements.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(16)
                        )
                        SummaryFieldRow(
                            questionNumber: 17,
                            label: "Doctor notes",
                            value: draft.clinicalInstructions.isEmpty ? nil : draft.clinicalInstructions,
                            isSkipped: draft.skippedQuestions.contains(17)
                        )
                    }

                    // Group 5: Nutrition & Lifestyle
                    SummaryGroupCard(title: "Nutrition & Lifestyle (Q18–Q21)", stepNumber: 5, onEdit: { onEditStep?(5) }) {
                        SummaryFieldRow(questionNumber: 18, label: "Diet preference", value: draft.dietaryPreference?.title, isSkipped: draft.skippedQuestions.contains(18))
                        SummaryFieldRow(questionNumber: 19, label: "Restrictions", value: draft.dietaryRestrictionsNotes.isEmpty ? nil : draft.dietaryRestrictionsNotes, isSkipped: draft.skippedQuestions.contains(19))
                        SummaryFieldRow(questionNumber: 20, label: "Meal tracking", value: draft.mealTrackingPreference.title, isSkipped: draft.skippedQuestions.contains(20))
                        SummaryFieldRow(
                            questionNumber: 21,
                            label: "Lifestyle habits",
                            value: draft.lifestyleTrackingPriorities.isEmpty ? nil : draft.lifestyleTrackingPriorities.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(21)
                        )
                    }

                    // Group 6: Connected Health
                    SummaryGroupCard(title: "Connected Health (Q22–Q24)", stepNumber: 6, onEdit: { onEditStep?(6) }) {
                        SummaryFieldRow(
                            questionNumber: 22,
                            label: "Trackers & devices",
                            value: draft.connectedDevices.isEmpty ? nil : draft.connectedDevices.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(22)
                        )
                        SummaryFieldRow(
                            questionNumber: 23,
                            label: "Apple Health",
                            value: draft.connectedAppleHealth ? "Connected" : "Not connected",
                            isSkipped: draft.skippedQuestions.contains(23)
                        )
                        SummaryFieldRow(
                            questionNumber: 24,
                            label: "Measurements",
                            value: draft.measurementsOfInterest.isEmpty ? nil : draft.measurementsOfInterest.joined(separator: ", "),
                            isSkipped: draft.skippedQuestions.contains(24)
                        )
                    }

                    // Group 7: Care & Reminders
                    SummaryGroupCard(title: "Care & Reminders (Q25)", stepNumber: 7, onEdit: { onEditStep?(7) }) {
                        SummaryFieldRow(
                            questionNumber: 25,
                            label: "Active reminders",
                            value: draft.selectedReminders.isEmpty ? "None enabled" : "\(draft.selectedReminders.count) categories active",
                            isSkipped: draft.skippedQuestions.contains(25)
                        )
                    }

                    // Medical Safety Boundary Card
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("A gentle medical boundary", systemImage: "hand.raised.shield.fill")
                                .font(.headline)
                                .foregroundStyle(Color("AccentColor"))

                            Text("MamAmie organizes what you choose to record. It does not diagnose symptoms, prescribe medication, or replace your healthcare provider.")
                                .font(.caption)
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
        .onAppear {
            draft.acceptedPrivacy = true
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
            Text("Review & Continue")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Review your personalized answers. You can change them anytime in your Profile.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 8) {
            OnboardingPrimaryButton(
                title: "Enter MamAmie",
                systemImage: "arrow.right",
                isDisabled: profile == nil,
                action: onFinish
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Views for Summary
private struct SummaryGroupCard<Content: View>: View {
    let title: String
    let stepNumber: Int
    var onEdit: (() -> Void)? = nil
    let content: Content

    init(title: String, stepNumber: Int, onEdit: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.stepNumber = stepNumber
        self.onEdit = onEdit
        self.content = content()
    }

    var body: some View {
        OnboardingCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))

                    Spacer()

                    if let onEdit {
                        Button(action: onEdit) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AccentColor"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                content
            }
        }
    }
}

private struct SummaryFieldRow: View {
    var questionNumber: Int? = nil
    let label: String
    let value: String?
    var isSkipped: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 4) {
                if let questionNumber {
                    Text("Q\(questionNumber)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 130, alignment: .leading)

            Spacer()

            if isSkipped {
                Text("Skipped")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            } else if let value, !value.isEmpty {
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("Not added · Optional")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
