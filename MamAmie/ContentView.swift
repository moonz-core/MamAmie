import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingStore: OnboardingStore
    @ObservedObject var journalStore: JournalStore
    @ObservedObject var foodDiaryStore: FoodDiaryStore
    @ObservedObject var assistantAPI: AssistantAPIClient
    @ObservedObject var watchBridge: WatchConnectivityBridge
    @State private var showingOnboarding = false
    @State private var onboardingSessionID = UUID()

    init(
        onboardingStore: OnboardingStore,
        journalStore: JournalStore,
        foodDiaryStore: FoodDiaryStore,
        assistantAPI: AssistantAPIClient,
        watchBridge: WatchConnectivityBridge
    ) {
        self.onboardingStore = onboardingStore
        self.journalStore = journalStore
        self.foodDiaryStore = foodDiaryStore
        self.assistantAPI = assistantAPI
        self.watchBridge = watchBridge
    }

    var body: some View {
        Group {
            if onboardingStore.isComplete && !showingOnboarding {
                AppTabView(
                    onboardingStore: onboardingStore,
                    journalStore: journalStore,
                    foodDiaryStore: foodDiaryStore,
                    assistantAPI: assistantAPI,
                    onEditOnboarding: {
                        onboardingSessionID = UUID()
                        showingOnboarding = true
                    },
                    onClearData: {
                        journalStore.reset()
                        foodDiaryStore.reset()
                        onboardingStore.reset()
                        showingOnboarding = false
                        onboardingSessionID = UUID()
                    }
                )
            } else {
                OnboardingFlowView(
                    store: onboardingStore,
                    onFinished: {
                        showingOnboarding = false
                    }
                )
                .id(onboardingSessionID)
            }
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
        ContentView(
            onboardingStore: OnboardingStore(),
            journalStore: JournalStore(),
            foodDiaryStore: FoodDiaryStore(),
            assistantAPI: AssistantAPIClient(),
            watchBridge: WatchConnectivityBridge()
        )
    }
}
