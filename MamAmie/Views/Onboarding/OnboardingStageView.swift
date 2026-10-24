import SwiftUI

struct OnboardingNameView: View {
    @Binding var name: String
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("Enter your name or preferred nickname for a warm, personalized experience. This is completely optional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            OnboardingCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    TextField("e.g. Maya (optional)", text: $name)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isDisabled: false,
                    action: onContinue
                )

                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    OnboardingSkipButton(title: "Skip for now", action: onSkip)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct OnboardingStageView: View {
    @Binding var stage: OnboardingStage?
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Which stage of your journey are you in?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("We tailor your questions, guidance, and daily timeline to where you are right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(OnboardingStage.allCases) { option in
                    StageOptionRow(
                        stage: option,
                        isSelected: stage == option
                    ) {
                        stage = option
                    }
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: stage == nil,
                action: onContinue
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

private struct StageOptionRow: View {
    let stage: OnboardingStage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: stage.iconName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.white : Color("AccentColor"))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color("AccentColor") : Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(stage.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("AccentColor") : Color(.tertiaryLabel))
            }
            .padding(16)
            .background(isSelected ? Color("AccentColor").opacity(0.10) : Color(.secondarySystemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color("AccentColor") : .clear, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
