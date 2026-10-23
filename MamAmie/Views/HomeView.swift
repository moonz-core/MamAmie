import SwiftUI

struct HomeView: View {
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

                            Text("Dates not set")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text("Add reliable pregnancy dates when you are ready to see week-by-week context.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

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
