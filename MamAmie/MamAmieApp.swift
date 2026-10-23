import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var onboardingStore = OnboardingStore()
    @StateObject private var journalStore = JournalStore()
    @StateObject private var foodDiaryStore = FoodDiaryStore()

    var body: some Scene {
        WindowGroup {
            ContentView(
                onboardingStore: onboardingStore,
                journalStore: journalStore,
                foodDiaryStore: foodDiaryStore
            )
        }
    }
}
