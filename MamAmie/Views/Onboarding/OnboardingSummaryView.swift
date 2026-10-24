import SwiftUI

struct OnboardingSummaryView: View {
    let draft: OnboardingDraft
    let onFinish: () -> Void
    let onBack: () -> Void

    private var profile: OnboardingProfile? {
        draft.makeProfile()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("You are all set")
                    .font(.largeTitle.bold())
                Text("Review your answers before entering MamAmie. You can change them later from Profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let profile {
                VStack(spacing: 12) {
                    OnboardingSummaryRow(title: "Your journey", value: profile.stageSummary, icon: profile.stage.iconName)
                    OnboardingSummaryRow(title: "Pregnancy dates", value: profile.dateSummary, icon: "calendar")
                    OnboardingSummaryRow(
                        title: "Name",
                        value: profile.displayName.isEmpty ? "Not added" : profile.displayName,
                        icon: "person.fill"
                    )
                }
            }

            OnboardingCard {
                Label("A gentle boundary", systemImage: "cross.case.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))
                Text("MamAmie organizes what you choose to record. It does not diagnose symptoms, prescribe medication, or replace your healthcare professional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                .frame(width: 34, height: 34)
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
