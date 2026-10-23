import SwiftUI

struct ContentView: View {
    @ObservedObject var journalStore: JournalStore
    @ObservedObject var foodDiaryStore: FoodDiaryStore
    @ObservedObject var watchBridge: WatchConnectivityBridge
    @State private var selectedTab = 0

    init(journalStore: JournalStore, foodDiaryStore: FoodDiaryStore, watchBridge: WatchConnectivityBridge) {
        self.journalStore = journalStore
        self.foodDiaryStore = foodDiaryStore
        self.watchBridge = watchBridge
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                onOpenHealth: { selectedTab = 1 },
                onOpenAssistant: { selectedTab = 6 },
                onOpenFood: { selectedTab = 5 }
            )
                .tabItem {
                    Label("Today", systemImage: "heart.fill")
                }
                .tag(0)

            ConnectedHealthDashboardView()
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

            AssistantView()
                .tabItem {
                    Label("Ask", systemImage: "heart.text.clipboard")
                }
                .tag(6)

            FoodScannerView(store: foodDiaryStore)
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

            PlaceholderView(
                title: "Profile",
                message: "Personalize MamAmie and keep your preferences in one place.",
                systemImage: "person.crop.circle"
            )
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(4)

        }
        .tint(Color("AccentColor"))
        .onAppear {
            watchBridge.activate(journalStore: journalStore)
            watchBridge.publishLatestSnapshot()
        }
        .onChange(of: journalStore.entries) { _ in watchBridge.publishLatestSnapshot() }
        .onChange(of: journalStore.medicationSchedules) { _ in watchBridge.publishLatestSnapshot() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(journalStore: JournalStore(), foodDiaryStore: FoodDiaryStore(), watchBridge: WatchConnectivityBridge())
    }
}
