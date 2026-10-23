import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var journalStore = JournalStore()

    var body: some Scene {
        WindowGroup {
            ContentView(journalStore: journalStore)
        }
    }
}
