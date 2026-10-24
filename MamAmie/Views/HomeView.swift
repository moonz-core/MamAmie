import SwiftUI

struct HomeView: View {
    let profile: OnboardingProfile?
    let onOpenHealth: () -> Void
    var onOpenAssistant: (() -> Void)? = nil
    var onOpenFood: (() -> Void)? = nil
    @State private var waterGlasses: Int = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    journeyCard
                    connectedHealthCard
                    wellnessSnapshot
                    featureLinks
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

    private var wellnessSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today’s wellness at a glance")
                    .font(.title3.bold())

                Spacer()

                Text("Live")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        Text("Hydration")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            if waterGlasses < 10 { waterGlasses += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .accessibilityLabel("Add a glass of water")
                    }

                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color.blue.opacity(0.15), lineWidth: 5)
                                .frame(width: 44, height: 44)
                            Circle()
                                .trim(from: 0, to: min(1.0, Double(waterGlasses) / 8.0))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 44, height: 44)
                            Text("\(waterGlasses)")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(waterGlasses * 250) ml")
                                .font(.subheadline.bold())
                            Text("Goal: 2,000 ml")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Button(action: onOpenHealth) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.42))
                            Text("Vitals")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("72 bpm")
                                .font(.caption.bold())
                                .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.42))
                        }

                        HStack(alignment: .bottom, spacing: 4) {
                            let heights: [CGFloat] = [12, 16, 14, 20, 18, 22, 19]
                            ForEach(0..<heights.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index == heights.count - 1
                                          ? Color(red: 0.90, green: 0.28, blue: 0.42)
                                          : Color(red: 0.90, green: 0.28, blue: 0.42).opacity(0.35))
                                    .frame(width: 5, height: heights[index])
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("7.5h rest")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                Text("Steady baseline")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 28)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featureLinks: some View {
        VStack(spacing: 10) {
            Button { onOpenAssistant?() } label: {
                FeatureEntryCard(
                    icon: "heart.text.clipboard.fill",
                    title: "Ask MamAmie",
                    detail: "Explore maternal-health guidance with sources",
                    tint: Color("AccentColor")
                )
            }
            .buttonStyle(.plain)

            Button { onOpenFood?() } label: {
                FeatureEntryCard(
                    icon: "fork.knife.circle.fill",
                    title: "Food & nutrition",
                    detail: "Scan or log a meal",
                    tint: Color("AccentColor")
                )
            }
            .buttonStyle(.plain)
        }
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

private struct FeatureEntryCard: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
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
