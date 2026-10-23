import SwiftUI

struct AppTabView: View {
    @ObservedObject var onboardingStore: OnboardingStore
    let onEditOnboarding: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                profile: onboardingStore.profile,
                onOpenHealth: { selectedTab = 1 }
            )
            .tabItem {
                Label("Today", systemImage: "heart.fill")
            }
            .tag(0)

            ConnectedHealthDashboardView(initialProfile: healthProfile)
                .tabItem {
                    Label("Health", systemImage: "waveform.path.ecg")
                }
                .tag(1)

            PlaceholderView(
                title: "Journal",
                message: "Keep notes about how you are feeling and the moments you want to remember.",
                systemImage: "book.closed.fill"
            )
            .tabItem {
                Label("Journal", systemImage: "book.closed.fill")
            }
            .tag(2)

            PlaceholderView(
                title: "Resources",
                message: "Helpful guidance for each step of your pregnancy will live here.",
                systemImage: "sparkles"
            )
            .tabItem {
                Label("Resources", systemImage: "sparkles")
            }
            .tag(3)

            ProfileView(
                profile: onboardingStore.profile,
                onEditOnboarding: onEditOnboarding
            )
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(4)
        }
        .tint(Color("AccentColor"))
    }

    private var healthProfile: MaternalHealthProfile {
        guard let profile = onboardingStore.profile else {
            return MaternalHealthProfile()
        }

        let stage: MaternalStage
        switch profile.stage {
        case .planning: stage = .planning
        case .pregnant:
            switch profile.gestationalWeek ?? 0 {
            case 0...13: stage = .firstTrimester
            case 14...27: stage = .secondTrimester
            default: stage = .thirdTrimester
            }
        case .postpartum: stage = .postpartum
        }

        return MaternalHealthProfile(
            stage: stage,
            gestationalWeek: profile.gestationalWeek,
            userName: profile.displayName.isEmpty ? "Mama" : profile.displayName
        )
    }
}
