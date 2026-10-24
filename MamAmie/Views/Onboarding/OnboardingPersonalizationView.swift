import SwiftUI

struct OnboardingPersonalizationView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Make it feel like yours")
                    .font(.largeTitle.bold())
                Text("A few final choices help us keep the experience personal and respectful.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            OnboardingCard {
                Text("What should we call you?")
                    .font(.headline)
                TextField("Your name (optional)", text: $draft.displayName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
            }

            OnboardingCard {
                Toggle(isOn: $draft.acceptedPrivacy) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keep my setup private on this device")
                            .font(.subheadline.weight(.semibold))
                        Text("Your onboarding answers are saved locally. MamAmie does not upload them as part of this setup.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color("AccentColor"))
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Review setup",
                systemImage: "checkmark",
                isDisabled: !draft.acceptedPrivacy,
                action: onContinue
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}
