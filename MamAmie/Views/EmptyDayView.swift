import SwiftUI

struct EmptyDayView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 34))
                .foregroundStyle(Color("AccentColor"))

            Text("Nothing recorded yet")
                .font(.headline)

            Text("Add a note, medication, appointment, photo, or anything you want to remember about this day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add an entry", action: action)
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(Color("AccentColor").opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
