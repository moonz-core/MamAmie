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
                    stageResourcesCard
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(greetingText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(greetingTitle)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))
            }

            Spacer(minLength: 12)

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color("AccentColor").opacity(0.18), lineWidth: 1.5))
                .shadow(color: Color("AccentColor").opacity(0.12), radius: 6, x: 0, y: 2)
        }
    }

    private var greetingTitle: String {
        switch profile?.stage {
        case .pregnant: return "Your pregnancy, supported."
        case .planning: return "Preparing for pregnancy."
        case .postpartum: return "Postpartum recovery & care."
        case .none: return "Your journey, supported."
        }
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your journey", systemImage: profile?.stage.iconName ?? "heart.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                Text(profile?.stage.badgeLabel ?? "Your space")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            switch profile?.stage {
            case .pregnant:
                if let profile, let week = profile.gestationalWeek {
                    ProgressView(value: Double(min(week, 40)), total: 40)
                        .tint(Color("AccentColor"))
                    Text("Week \(week) of 40 · \(profile.dateSummary)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                } else {
                    Text(profile?.dateSummary ?? "Add your pregnancy dates in Profile to view gestational progress.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Every day is a new step. Stay hydrated and check in with your body today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .planning:
                VStack(alignment: .leading, spacing: 8) {
                    if profile?.trackCycle == true {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color("AccentColor"))
                            Text("Cycle tracking active")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Capsule())

                        Text("Track your periods and symptom patterns in the Calendar tab to monitor your cycles.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Pre-pregnancy preparation: Focus on balanced nutrition, restful sleep, and gentle daily habits.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

            case .postpartum:
                VStack(alignment: .leading, spacing: 8) {
                    if let childbirthDate = profile?.childbirthDate {
                        let days = Calendar.current.dateComponents([.day], from: childbirthDate, to: Date()).day ?? 0
                        let weeks = max(1, days / 7)
                        Text("Week \(weeks) Postpartum · Gentle Recovery")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Childbirth: \(childbirthDate.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Postpartum recovery support: Take each day at your own pace.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("Prioritize your physical healing, emotional wellbeing, and gentle nourishment alongside your newborn.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .none:
                Text("Complete onboarding to personalize your journey timeline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color("AccentColor").opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stageResourcesCard: some View {
        Group {
            switch profile?.stage {
            case .planning:
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Color("AccentColor"))
                        .frame(width: 44, height: 44)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pre-Pregnancy Guidance")
                            .font(.subheadline.weight(.semibold))
                        Text("Folic acid, cycle awareness, and holistic wellbeing tips.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            case .postpartum:
                HStack(spacing: 14) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.title2)
                        .foregroundStyle(Color("AccentColor"))
                        .frame(width: 44, height: 44)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Postpartum & Newborn Care")
                            .font(.subheadline.weight(.semibold))
                        Text("Healing milestones, feeding support, and sleep restoration.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            default:
                EmptyView()
            }
        }
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

                        if profile?.connectedAppleHealth == true {
                            Text("Active Sync")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        } else {
                            Text("Apple Watch")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("AccentColor").opacity(0.12))
                                .foregroundStyle(Color("AccentColor"))
                                .clipShape(Capsule())
                        }
                    }

                    Text(profile?.connectedAppleHealth == true
                         ? "View heart rate, rest, and sleep trends"
                         : "Connect Apple Health or smartwatch anytime")
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
                    icon: "sparkles.bubble.fill",
                    title: "Ask MamAmie AI",
                    detail: "Gemini-powered companion with your live dates & food",
                    tint: Color("AccentColor")
                )
            }
            .buttonStyle(.plain)

            Button { onOpenFood?() } label: {
                FeatureEntryCard(
                    icon: "fork.knife.circle.fill",
                    title: "Food & nutrition",
                    detail: profile?.dietaryPreference != nil ? "Diet: \(profile!.dietaryPreference!.title)" : "Scan or log a meal",
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

            Text(reminderText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var reminderText: String {
        switch profile?.stage {
        case .pregnant:
            return "There is no one right way to experience pregnancy. Listen to your body and reach out to your care team whenever you need support."
        case .planning:
            return "Preparing for pregnancy is a gradual, personal journey. Nurture your daily wellness, balanced nutrition, and peaceful rest."
        case .postpartum:
            return "Postpartum healing takes time and gentle patience. Allow yourself to rest, bond with your baby, and ask for support whenever you need it."
        case .none:
            return "Take each day one step at a time. Listen to your body and check in whenever you need support."
        }
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
