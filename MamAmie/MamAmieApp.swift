import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var journalStore = JournalStore()
    @StateObject private var foodDiaryStore = FoodDiaryStore()
    @StateObject private var assistantAPI = AssistantAPIClient()

    var body: some Scene {
        WindowGroup {
            ContentView(journalStore: journalStore, foodDiaryStore: foodDiaryStore, assistantAPI: assistantAPI)
        }
    }
}
