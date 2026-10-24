import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color("AccentColor").opacity(0.12))
                    .frame(width: 110, height: 110)

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("AccentColor"))
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Welcome to MamAmie AI")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("AccentColor"))

                Text("A personalized maternal-health companion designed to support you with calm, thoughtful care at every stage.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                OnboardingCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.title3)
                            .foregroundStyle(Color("AccentColor"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tailored to your journey")
                                .font(.subheadline.weight(.semibold))
                            Text("Answer a few quick questions to personalize insights and reminders.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                OnboardingCard {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundStyle(Color("AccentColor"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Private & on-device")
                                .font(.subheadline.weight(.semibold))
                            Text("Your answers stay securely on your device and can be updated anytime.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Get Started",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}
