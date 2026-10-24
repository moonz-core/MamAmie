import SwiftUI

struct AppTabView: View {
    @ObservedObject var onboardingStore: OnboardingStore
    @ObservedObject var journalStore: JournalStore
    @ObservedObject var foodDiaryStore: FoodDiaryStore
    @ObservedObject var assistantAPI: AssistantAPIClient
    let onEditOnboarding: () -> Void
    var onClearData: (() -> Void)? = nil
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                profile: onboardingStore.profile,
                onOpenHealth: { selectedTab = 1 },
                onOpenAssistant: { selectedTab = 6 },
                onOpenFood: { selectedTab = 5 }
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

            NavigationStack {
                CalendarJournalView(store: journalStore)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(2)

            FoodScannerView(store: foodDiaryStore, assistantAPI: assistantAPI)
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(5)

            MaternalAIView(
                onOpenHealth: { selectedTab = 1 },
                onOpenFood: { selectedTab = 5 }
            )
            .tabItem {
                Label("Guidance", systemImage: "sparkles")
            }
            .tag(3)

            AssistantView(
                api: assistantAPI,
                onboardingStore: onboardingStore,
                foodDiaryStore: foodDiaryStore
            )
            .tabItem {
                Label("Ask", systemImage: "sparkles.bubble")
            }
            .tag(6)

            ProfileView(
                profile: onboardingStore.profile,
                onEditOnboarding: onEditOnboarding,
                onClearData: {
                    if let onClearData {
                        onClearData()
                    } else {
                        journalStore.reset()
                        foodDiaryStore.reset()
                        onboardingStore.reset()
                    }
                }
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
