import SwiftUI

struct ProfileView: View {
    let profile: OnboardingProfile?
    let onEditOnboarding: () -> Void
    var onClearData: (() -> Void)? = nil

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    journeyCard
                    preferencesCard
                    privacyCard
                    dataManagementCard

                    Button(action: onEditOnboarding) {
                        Label("Review onboarding questions", systemImage: "pencil")
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
            .confirmationDialog(
                "Clear all app data?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear data & retake onboarding", role: .destructive) {
                    onClearData?()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete your profile, onboarding answers, calendar entries, medication schedules, and food diary. You will immediately be taken back to Question 1 of the onboarding questions.")
            }
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
                Text(profile.stageDetailSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if profile.clinicalCareStatus != .unspecified {
                    Text("Care: \(profile.clinicalCareStatus.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Preferences & Connected Devices", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))

            VStack(spacing: 10) {
                ProfileDetailRow(
                    title: "Dietary preference",
                    value: profile?.dietaryPreference?.title ?? "None specified",
                    icon: profile?.dietaryPreference?.iconName ?? "fork.knife"
                )

                if let notes = profile?.healthConditionsAndAllergies, !notes.isEmpty {
                    ProfileDetailRow(
                        title: "Health & allergies",
                        value: notes,
                        icon: "cross.case.fill"
                    )
                }

                ProfileDetailRow(
                    title: "Apple Health & Watch",
                    value: profile?.connectedAppleHealth == true ? "Connected" : "Not connected",
                    icon: "applewatch"
                )

                ProfileDetailRow(
                    title: "Active reminders",
                    value: profile?.selectedReminders.isEmpty == false ? "\(profile!.selectedReminders.count) categories active" : "None active",
                    icon: "bell.badge.fill"
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Privacy first", systemImage: "lock.shield.fill")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
            Text("Onboarding answers are stored locally using the app's device storage. You can review or update them anytime from this screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Data Management", systemImage: "internaldrive")
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))

            Text("Your journey profile, calendar journal entries, medication schedules, and food diary are stored exclusively on this device. You can reset and clear all data anytime.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Clear all app data", systemImage: "trash.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProfileDetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 32, height: 32)
                .background(Color("AccentColor").opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }
}
