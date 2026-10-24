import SwiftUI

struct ProfileView: View {
    let profile: OnboardingProfile?
    let onEditOnboarding: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    journeyCard
                    privacyCard

                    Button(action: onEditOnboarding) {
                        Label("Review onboarding answers", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("AccentColor"))

            Text(displayName)
                .font(.largeTitle.bold())

            Text("Your setup stays private on this device and can be changed whenever you need.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var displayName: String {
        guard let name = profile?.displayName, !name.isEmpty else {
            return "Your MamAmie profile"
        }
        return name
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your journey", systemImage: profile?.stage.iconName ?? "heart.fill")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))

            if let profile {
                Text(profile.stageSummary)
                    .font(.title3.bold())
                Text(profile.dateSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Complete onboarding to personalize MamAmie.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AccentColor").opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Privacy first", systemImage: "lock.shield.fill")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
            Text("Onboarding answers are stored locally using the app's device storage. You can review or update them from this screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
