import SwiftUI

struct EntryDetailHeader: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: entry.category.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 52, height: 52)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.title2.bold())
                    Text(entry.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Label(LocalDay.dateText(for: entry.dayKey, style: .long), systemImage: "calendar")
                if let timeMinutes = entry.timeMinutes {
                    Label(LocalDay.timeText(for: timeMinutes), systemImage: "clock")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

struct DetailCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct DetailLineView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct NotesCardView: View {
    let notes: String

    @ViewBuilder
    var body: some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                Text(notes)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
