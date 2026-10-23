import SwiftUI

struct TimelineRowView: View {
    let item: TimelineItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.category.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 38, height: 38)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer(minLength: 0)

                        if let timeMinutes = item.timeMinutes {
                            Text(LocalDay.timeText(for: timeMinutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(item.category.shortName)
                        if let status = item.status {
                            Text("·")
                            Text(status)
                        }
                        if item.hasAttachment {
                            Image(systemName: "paperclip")
                                .accessibilityLabel("Has attachment")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(Color("AccentColor"))
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 10)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.07))
                .frame(height: 1)
                .padding(.leading, 50)
        }
    }
}
