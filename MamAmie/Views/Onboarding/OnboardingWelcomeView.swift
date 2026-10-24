import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 78))
                .foregroundStyle(Color("AccentColor"))
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Welcome to MamAmie")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("AccentColor"))

                Text("A calm, private companion for your pregnancy and healthcare journey.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            OnboardingCard {
                Label("Your choices stay yours", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))
                Text("We will use your answers to personalize the app on this device. You can review or change them later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Begin setup",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}
