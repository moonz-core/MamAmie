import SwiftUI

struct CalendarHeaderView: View {
    let onToday: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your personal timeline")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("Your Journey")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color("AccentColor"))
                }

                Spacer(minLength: 0)

                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(Color("AccentColor").opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("AccentColor"))
                .accessibilityLabel("Select today")
            }

            Text("A private place to remember what matters to you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
