import SwiftUI

public struct WeeklyWellbeingSummaryCard: View {
    public let summary: PersonalHealthSummary?
    public let profile: MaternalHealthProfile

    public init(summary: PersonalHealthSummary?, profile: MaternalHealthProfile) {
        self.summary = summary
        self.profile = profile
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Weekly Wellbeing Summary", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                Text(profile.formattedStageSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let summary = summary, summary.isSufficientDataAvailable {
                VStack(alignment: .leading, spacing: 14) {
                    SummaryRow(
                        icon: "heart.fill",
                        iconColor: Color(red: 0.90, green: 0.28, blue: 0.42),
                        title: "Heart Rate Baseline",
                        text: summary.restingHeartRateObservation
                    )

                    SummaryRow(
                        icon: "moon.stars.fill",
                        iconColor: Color(red: 0.38, green: 0.45, blue: 0.78),
                        title: "Sleep Duration",
                        text: summary.sleepObservation
                    )

                    SummaryRow(
                        icon: "figure.walk",
                        iconColor: Color(red: 0.24, green: 0.72, blue: 0.58),
                        title: "Movement & Steps",
                        text: summary.activityObservation
                    )
                }

                Divider()

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(summary.overallObservation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gathering your baseline")
                        .font(.subheadline.weight(.semibold))

                    Text("Wear your smartwatch regularly over the next few days to unlock statistical comparisons for resting heart rate, sleep patterns, and daily steps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(Color("AccentColor").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct SummaryRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
