import SwiftUI

struct OnboardingSummaryView: View {
    @Binding var draft: OnboardingDraft
    let onFinish: () -> Void
    let onBack: () -> Void

    private var profile: OnboardingProfile? {
        draft.makeProfile()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("You are all set")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("Review your choices before entering MamAmie. You can change them anytime in Profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if let profile {
                        OnboardingSummaryRow(
                            title: "Name",
                            value: profile.displayName.isEmpty ? "Not specified" : profile.displayName,
                            icon: "person.fill"
                        )

                        OnboardingSummaryRow(
                            title: "Your journey",
                            value: profile.stageSummary,
                            icon: profile.stage.iconName
                        )

                        OnboardingSummaryRow(
                            title: stageDetailTitle(profile.stage),
                            value: profile.stageDetailSummary,
                            icon: stageDetailIcon(profile.stage)
                        )

                        OnboardingSummaryRow(
                            title: "Dietary preference",
                            value: profile.dietaryPreference?.title ?? "None specified",
                            icon: profile.dietaryPreference?.iconName ?? "fork.knife"
                        )

                        if !profile.healthConditionsAndAllergies.isEmpty {
                            OnboardingSummaryRow(
                                title: "Health & allergies",
                                value: profile.healthConditionsAndAllergies,
                                icon: "cross.case.fill"
                            )
                        }

                        OnboardingSummaryRow(
                            title: "Apple Health",
                            value: profile.connectedAppleHealth ? "Connected" : "Not connected (can add later)",
                            icon: "applewatch"
                        )

                        OnboardingSummaryRow(
                            title: "Active reminders",
                            value: remindersSummary(profile.selectedReminders),
                            icon: "bell.badge.fill"
                        )
                    }

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
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Enter MamAmie",
                systemImage: "arrow.right",
                isDisabled: profile == nil,
                action: onFinish
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .onAppear {
            draft.acceptedPrivacy = true
        }
    }

    private func stageDetailTitle(_ stage: OnboardingStage) -> String {
        switch stage {
        case .pregnant: return "Pregnancy timeline"
        case .planning: return "Cycle tracking"
        case .postpartum: return "Postpartum details"
        }
    }

    private func stageDetailIcon(_ stage: OnboardingStage) -> String {
        switch stage {
        case .pregnant: return "calendar"
        case .planning: return "calendar.badge.clock"
        case .postpartum: return "heart.circle.fill"
        }
    }

    private func remindersSummary(_ reminders: [OnboardingReminderType]) -> String {
        if reminders.isEmpty { return "None selected" }
        if reminders.count == OnboardingReminderType.allCases.count {
            return "All reminders enabled"
        }
        return "\(reminders.count) reminder categories active"
    }
}

private struct OnboardingSummaryRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 36, height: 36)
                .background(Color("AccentColor").opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
