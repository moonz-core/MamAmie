import SwiftUI

struct HomeView: View {
    let profile: OnboardingProfile?
    let onOpenHealth: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    journeyCard
                    connectedHealthCard
                    checkInSection
                    reminderCard
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("MamAmie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Your pregnancy, supported.")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
        }
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your journey", systemImage: "figure.and.child.holdinghands")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                Text(profile?.stage.badgeLabel ?? "Your space")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let profile, let week = profile.gestationalWeek {
                ProgressView(value: Double(week), total: 40)
                    .tint(Color("AccentColor"))
                Text("Week \(week) · \(profile.dateSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(profile?.dateSummary ?? "Your personal journey will take shape here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Every day is a new step. Take a moment to check in with yourself today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(Color("AccentColor").opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var connectedHealthCard: some View {
        Button(action: onOpenHealth) {
            HStack(spacing: 14) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 44, height: 44)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Connected Health")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Apple Watch")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("AccentColor").opacity(0.12))
                            .foregroundStyle(Color("AccentColor"))
                            .clipShape(Capsule())
                    }

                    Text("View heart rate, rest, and sleep trends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var checkInSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today’s check-in")
                .font(.title3.bold())

            CheckInRow(icon: "drop.fill", title: "Hydration", detail: "Remember to drink some water")
            CheckInRow(icon: "figure.mind.and.body", title: "How are you feeling?", detail: "A quick moment for yourself")
            CheckInRow(icon: "moon.fill", title: "Rest", detail: "Make space for a little downtime")
        }
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A gentle reminder")
                .font(.headline)

            Text("There is no one right way to experience pregnancy. Listen to your body and reach out to your care team whenever you need support.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var greetingText: String {
        guard let name = profile?.displayName, !name.isEmpty else { return "Good morning" }
        return "Good morning, \(name)"
    }
}

private struct CheckInRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 42, height: 42)
                .background(Color("AccentColor").opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
