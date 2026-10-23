import SwiftUI

@main
struct MamAmieApp: App {
    @StateObject private var onboardingStore = OnboardingStore()

    var body: some Scene {
        WindowGroup {
            ContentView(onboardingStore: onboardingStore)
        }
    }
}
