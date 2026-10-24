import SwiftUI

struct MaternalMoodOption: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let iconName: String
    let color: Color
    let affirmation: String
}

struct DayMoodTrackerView: View {
    @ObservedObject var store: JournalStore
    let dayKey: String

    @State private var showingNoteField: Bool = false
    @State private var noteText: String = ""

    static let moodOptions: [MaternalMoodOption] = [
        MaternalMoodOption(
            id: "Radiant",
            name: "Radiant",
            emoji: "🌸",
            iconName: "sparkles",
            color: .pink,
            affirmation: "Embrace this glowing energy! You and your little one are thriving today."
        ),
        MaternalMoodOption(
            id: "Calm",
            name: "Calm",
            emoji: "🌿",
            iconName: "leaf.fill",
            color: .green,
            affirmation: "Peaceful moments nourish your heart and your baby's developing nervous system."
        ),
        MaternalMoodOption(
            id: "Tired",
            name: "Tired",
            emoji: "😴",
            iconName: "moon.stars.fill",
            color: .indigo,
            affirmation: "Rest is vital productive work. Your body is building a whole human life."
        ),
        MaternalMoodOption(
            id: "Emotional",
            name: "Sensitive",
            emoji: "🌊",
            iconName: "heart.fill",
            color: .purple,
            affirmation: "Hormone shifts and deep emotions are natural. Give yourself gentle grace."
        ),
        MaternalMoodOption(
            id: "Anxious",
            name: "Anxious",
            emoji: "🌧️",
            iconName: "cloud.rain.fill",
            color: .blue,
            affirmation: "Take a slow, deep breath. One moment at a time, you have everything it takes."
        ),
        MaternalMoodOption(
            id: "Nauseous",
            name: "Nauseous",
            emoji: "🤢",
            iconName: "cross.vial.fill",
            color: .orange,
            affirmation: "Sip cool water or ginger tea. Remember, this intense phase is temporary."
        )
    ]

    private var existingJournalEntry: CalendarEntry? {
        store.entries(for: dayKey).first { $0.category == .journal }
    }

    private var activeMood: MaternalMoodOption? {
        guard let savedMood = existingJournalEntry?.journal?.mood, !savedMood.isEmpty else { return nil }
        return Self.moodOptions.first { $0.id.lowercased() == savedMood.lowercased() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(activeMood?.color ?? Color("AccentColor"))

                Text("How are you feeling today?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if activeMood != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingNoteField.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingNoteField ? "chevron.up" : "square.and.pencil")
                            Text(showingNoteField ? "Done" : "Add note")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color("AccentColor"))
                    }
                }
            }

            // Horizontal Mood Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Self.moodOptions) { mood in
                        let isSelected = activeMood?.id == mood.id

                        Button {
                            selectMood(mood)
                        } label: {
                            HStack(spacing: 6) {
                                Text(mood.emoji)
                                    .font(.subheadline)

                                Text(mood.name)
                                    .font(.caption.weight(isSelected ? .bold : .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? mood.color.opacity(0.18)
                                    : Color(.tertiarySystemBackground)
                            )
                            .foregroundStyle(isSelected ? mood.color : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? mood.color : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            // Affirmation text when a mood is selected
            if let activeMood = activeMood {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: activeMood.iconName)
                        .font(.caption)
                        .foregroundStyle(activeMood.color)
                        .padding(.top, 2)

                    Text(activeMood.affirmation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(activeMood.color.opacity(0.08))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            // Optional Note Input
            if showingNoteField {
                VStack(alignment: .trailing, spacing: 8) {
                    TextField("Write a gentle reflection or note for this day...", text: $noteText, axis: .vertical)
                        .font(.caption)
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator), lineWidth: 1)
                        )

                    Button("Save Note") {
                        saveNote()
                        withAnimation {
                            showingNoteField = false
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            if let existingNotes = existingJournalEntry?.notes {
                noteText = existingNotes
            }
        }
        .onChange(of: dayKey) { _ in
            noteText = existingJournalEntry?.notes ?? ""
            showingNoteField = false
        }
    }

    private func selectMood(_ mood: MaternalMoodOption) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let now = Date()
        if var existing = existingJournalEntry {
            existing.journal = JournalDetails(mood: mood.id)
            existing.modifiedAt = now
            store.upsertEntry(existing)
        } else {
            let newEntry = CalendarEntry(
                id: UUID(),
                title: "\(mood.emoji) \(mood.name) mood logged",
                category: .journal,
                dayKey: dayKey,
                timeMinutes: LocalDay.minutes(for: Date()),
                notes: noteText,
                createdAt: now,
                modifiedAt: now,
                attachments: [],
                journal: JournalDetails(mood: mood.id)
            )
            store.upsertEntry(newEntry)
        }
    }

    private func saveNote() {
        guard var existing = existingJournalEntry else {
            let now = Date()
            let newEntry = CalendarEntry(
                id: UUID(),
                title: "Personal journal reflection",
                category: .journal,
                dayKey: dayKey,
                timeMinutes: LocalDay.minutes(for: Date()),
                notes: noteText,
                createdAt: now,
                modifiedAt: now,
                attachments: [],
                journal: JournalDetails(mood: activeMood?.id ?? "Calm")
            )
            store.upsertEntry(newEntry)
            return
        }

        existing.notes = noteText
        existing.modifiedAt = Date()
        store.upsertEntry(existing)
    }
}
