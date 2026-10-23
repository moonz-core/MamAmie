import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingStore: OnboardingStore
    @State private var showingOnboarding = false

    init(onboardingStore: OnboardingStore) {
        self.onboardingStore = onboardingStore
    }

    var body: some View {
        Group {
            if onboardingStore.isComplete && !showingOnboarding {
                AppTabView(
                    onboardingStore: onboardingStore,
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
        ContentView(onboardingStore: OnboardingStore())
    }
}
