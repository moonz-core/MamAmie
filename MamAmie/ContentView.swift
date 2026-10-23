import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingStore: OnboardingStore
    @ObservedObject var journalStore: JournalStore
    @ObservedObject var foodDiaryStore: FoodDiaryStore
    @State private var showingOnboarding = false

    init(
        onboardingStore: OnboardingStore,
        journalStore: JournalStore,
        foodDiaryStore: FoodDiaryStore
    ) {
        self.onboardingStore = onboardingStore
        self.journalStore = journalStore
        self.foodDiaryStore = foodDiaryStore
    }

    var body: some View {
        Group {
            if onboardingStore.isComplete && !showingOnboarding {
                AppTabView(
                    onboardingStore: onboardingStore,
                    journalStore: journalStore,
                    foodDiaryStore: foodDiaryStore,
                    onEditOnboarding: { showingOnboarding = true }
                )
            } else {
                OnboardingFlowView(
                    store: onboardingStore,
                    onFinished: { showingOnboarding = false }
                )
            }
        }
        .tint(Color("AccentColor"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            onboardingStore: OnboardingStore(),
            journalStore: JournalStore(),
            foodDiaryStore: FoodDiaryStore()
        )
    }
}
