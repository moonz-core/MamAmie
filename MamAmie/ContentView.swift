import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "heart.fill")
                }
                .tag(0)

            PlaceholderView(
                title: "Journal",
                message: "Keep notes about how you are feeling and the moments you want to remember.",
                systemImage: "book.closed.fill"
            )
            .tabItem {
                Label("Journal", systemImage: "book.closed.fill")
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

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good morning")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("Your pregnancy, supported.")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("AccentColor"))
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Your journey", systemImage: "figure.and.child.holdinghands")
                                .font(.headline)
                                .foregroundStyle(Color("AccentColor"))

                            Spacer()

                            Text("Week 12")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: 12, total: 40)
                            .tint(Color("AccentColor"))

                        Text("Every day is a new step. Take a moment to check in with yourself today.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(Color("AccentColor").opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Today’s check-in")
                            .font(.title3.bold())

                        CheckInRow(icon: "drop.fill", title: "Hydration", detail: "Remember to drink some water")
                        CheckInRow(icon: "figure.mind.and.body", title: "How are you feeling?", detail: "A quick moment for yourself")
                        CheckInRow(icon: "moon.fill", title: "Rest", detail: "Make space for a little downtime")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("A gentle reminder")
                            .font(.headline)

                        Text("There is no one right way to experience pregnancy. Listen to your body and reach out to your care team whenever you need support.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("MamAmie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct CheckInRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color("AccentColor"))
                .frame(width: 42, height: 42)
                .background(Color("AccentColor").opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct PlaceholderView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(Color("AccentColor"))

                Text(title)
                    .font(.title.bold())

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
