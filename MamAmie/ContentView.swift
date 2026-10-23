import SwiftUI

struct ContentView: View {
    @ObservedObject var journalStore: JournalStore
    @State private var selectedTab = 0

    init(journalStore: JournalStore) {
        self.journalStore = journalStore
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "heart.fill")
                }
                .tag(0)

            NavigationStack {
                CalendarJournalView(store: journalStore)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)

            PlaceholderView(
                title: "Resources",
                message: "Helpful guidance for each step of your pregnancy will live here.",
                systemImage: "sparkles"
            )
            .tabItem {
                Label("Resources", systemImage: "sparkles")
            }
            .tag(2)

            PlaceholderView(
                title: "Profile",
                message: "Personalize MamAmie and keep your preferences in one place.",
                systemImage: "person.crop.circle"
            )
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(3)
        }
        .tint(Color("AccentColor"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(journalStore: JournalStore())
    }
}
