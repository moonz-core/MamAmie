import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var journalStore = JournalStore()
    @StateObject private var foodDiaryStore = FoodDiaryStore()

    var body: some Scene {
        WindowGroup {
            ContentView(journalStore: journalStore, foodDiaryStore: foodDiaryStore)
        }
    }
}
