import SwiftUI

struct DayTimelineView: View {
    @ObservedObject var store: JournalStore
    let dayKey: String
    let onAddEntry: () -> Void
    let onSelectEntry: (UUID) -> Void

    private var items: [TimelineItem] {
        store.timeline(for: dayKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your day")
                        .font(.title3.bold())
                    Text(LocalDay.dateText(for: dayKey, style: .long))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onAddEntry) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("AccentColor"))
            }

            if items.isEmpty {
                EmptyDayView(action: onAddEntry)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        TimelineRowView(item: item) {
                            switch item.source {
                            case let .entry(id):
                                onSelectEntry(id)
                            case let .doseLog(_, entryID):
                                onSelectEntry(entryID)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
