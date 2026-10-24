import SwiftUI

@main
struct MamAmieWatchApp: App {
    @StateObject private var companionStore = WatchCompanionStore()
    @StateObject private var heartRateService = WatchHeartRateService()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(store: companionStore, heartRate: heartRateService)
                .task { companionStore.activate() }
        }
    }
}
