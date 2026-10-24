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
                    SummaryGroupCard(title: "About You", stepNumber: 1, onEdit: { onEditStep?(1) }) {
                        SummaryFieldRow(label: "Name", value: draft.displayName.isEmpty ? nil : draft.displayName)
                        SummaryFieldRow(label: "Age", value: draft.calculatedAge != nil ? "\(draft.calculatedAge!) years old" : nil)
                        SummaryFieldRow(label: "Country", value: draft.country.isEmpty ? nil : draft.country)
                        SummaryFieldRow(label: "Language", value: draft.preferredLanguage)
                    }

                    // Group 2: Your Journey
                    SummaryGroupCard(title: "Pregnancy Journey", stepNumber: 2, onEdit: { onEditStep?(2) }) {
                        SummaryFieldRow(label: "Stage", value: draft.stage?.title)
                        SummaryFieldRow(label: "Timeline", value: profile?.dateSummary)
                        SummaryFieldRow(label: "Clinical Care", value: draft.clinicalCareStatus != .unspecified ? draft.clinicalCareStatus.title : nil)
                    }

                    // Group 3: Pregnancy History
                    SummaryGroupCard(title: "Pregnancy History", stepNumber: 3, onEdit: { onEditStep?(3) }) {
                        if let isFirst = draft.isFirstPregnancy {
                            SummaryFieldRow(label: "First pregnancy", value: isFirst ? "Yes" : "No")
                            if !isFirst {
                                SummaryFieldRow(label: "Total pregnancies", value: "\(draft.totalPregnancies)")
                                SummaryFieldRow(label: "Previous births", value: "\(draft.previousBirths)")
                            }
                        } else {
                            SummaryFieldRow(label: "Pregnancy history", value: nil)
                        }

                        if draft.stage == .pregnant || draft.stage == nil {
                            SummaryFieldRow(label: "Expecting", value: draft.multiplePregnancyType.title)
                        }

                        if !draft.previousComplicationsNotes.isEmpty {
                            SummaryFieldRow(label: "Complications / notes", value: draft.previousComplicationsNotes)
                        }
                    }

                    // Group 4: Your Health
                    SummaryGroupCard(title: "Your Health", stepNumber: 4, onEdit: { onEditStep?(4) }) {
                        SummaryFieldRow(
                            label: "Medical conditions",
                            value: draft.medicalConditions.isEmpty ? nil : draft.medicalConditions.joined(separator: ", ")
                        )
                        SummaryFieldRow(
                            label: "Allergies",
                            value: draft.allergies.isEmpty ? nil : draft.allergies.joined(separator: ", ")
                        )
                        SummaryFieldRow(
                            label: "Supplements",
                            value: draft.medicationsAndSupplements.isEmpty ? nil : draft.medicationsAndSupplements.joined(separator: ", ")
                        )
                        if !draft.clinicalInstructions.isEmpty {
                            SummaryFieldRow(label: "Clinician instructions", value: draft.clinicalInstructions)
                        }
                    }

                    // Group 5: Nutrition & Lifestyle
                    SummaryGroupCard(title: "Nutrition & Lifestyle", stepNumber: 5, onEdit: { onEditStep?(5) }) {
                        SummaryFieldRow(label: "Diet preference", value: draft.dietaryPreference?.title)
                        if !draft.dietaryRestrictionsNotes.isEmpty {
                            SummaryFieldRow(label: "Restrictions", value: draft.dietaryRestrictionsNotes)
                        }
                        SummaryFieldRow(label: "Meal tracking", value: draft.mealTrackingPreference.title)
                        SummaryFieldRow(
                            label: "Lifestyle habits",
                            value: draft.lifestyleTrackingPriorities.isEmpty ? nil : draft.lifestyleTrackingPriorities.joined(separator: ", ")
                        )
                    }

                    // Group 6: Connected Health
                    SummaryGroupCard(title: "Connected Health", stepNumber: 6, onEdit: { onEditStep?(6) }) {
                        SummaryFieldRow(
                            label: "Trackers & devices",
                            value: draft.connectedDevices.isEmpty ? nil : draft.connectedDevices.joined(separator: ", ")
                        )
                        SummaryFieldRow(
                            label: "Apple Health",
                            value: draft.connectedAppleHealth ? "Connected" : "Not connected (can connect later)"
                        )
                    }

                    // Group 7: Care & Reminders
                    SummaryGroupCard(title: "Care & Reminders", stepNumber: 7, onEdit: { onEditStep?(7) }) {
                        SummaryFieldRow(
                            label: "Active reminders",
                            value: draft.selectedReminders.isEmpty ? "None enabled" : "\(draft.selectedReminders.count) categories active"
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
    let label: String
    let value: String?

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            if let value, !value.isEmpty {
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("Optional · Not added")
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
