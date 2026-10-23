import SwiftUI

struct UpcomingSectionView: View {
    @ObservedObject var store: JournalStore
    let onSelectEntry: (UUID) -> Void

    private var upcomingEntries: [CalendarEntry] {
        store.upcomingEntries(from: LocalDay.key(for: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming up")
                .font(.title3.bold())

            if upcomingEntries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(upcomingEntries) { entry in
                        UpcomingEntryRow(entry: entry) {
                            onSelectEntry(entry.id)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .foregroundStyle(Color("AccentColor"))
            Text("Upcoming appointments, tests, medications, and tasks will appear here when you add them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct UpcomingEntryRow: View {
    let entry: CalendarEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: entry.category.systemImage)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 34, height: 34)
                    .background(Color("AccentColor").opacity(0.11))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(LocalDay.dateText(for: entry.dayKey)) · \(entry.category.shortName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.07))
                .frame(height: 1)
                .padding(.leading, 46)
        }
    }
}
