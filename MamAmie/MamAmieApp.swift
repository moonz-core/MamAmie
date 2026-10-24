import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var journalStore = JournalStore()
    @StateObject private var foodDiaryStore = FoodDiaryStore()
    @StateObject private var watchBridge = WatchConnectivityBridge()

    var body: some Scene {
        WindowGroup {
            ContentView(journalStore: journalStore, foodDiaryStore: foodDiaryStore, watchBridge: watchBridge)
        }
    }
}
