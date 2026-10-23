import SwiftUI

struct CalendarJournalView: View {
    @ObservedObject var store: JournalStore

    @State private var selectedDate = Date()
    @State private var displayedMonth = LocalDay.startOfMonth(for: Date())
    @State private var showingAddEntry = false
    @State private var selectedEntry: CalendarEntrySelection?

    private var selectedDayKey: String {
        LocalDay.key(for: selectedDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CalendarHeaderView {
                    selectedDate = Date()
                    displayedMonth = LocalDay.startOfMonth(for: selectedDate)
                }

                MonthCalendarView(
                    store: store,
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate
                )

                DayTimelineView(
                    store: store,
                    dayKey: selectedDayKey,
                    onAddEntry: { showingAddEntry = true },
                    onSelectEntry: { selectedEntry = CalendarEntrySelection(id: $0) }
                )

                UpcomingSectionView(store: store) {
                    selectedEntry = CalendarEntrySelection(id: $0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Your Journey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Add a journal entry")
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntrySheet(store: store, date: selectedDate)
        }
        .sheet(item: $selectedEntry) { selection in
            NavigationStack {
                EntryDetailView(store: store, entryID: selection.id)
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { store.clearError() }
        } message: {
            Text(store.lastErrorMessage ?? "Please try again.")
        }
        .onChange(of: selectedDate) { newDate in
            let month = LocalDay.startOfMonth(for: newDate)
            if month != displayedMonth {
                displayedMonth = month
            }
        }
    }
}

struct CalendarEntrySelection: Identifiable {
    let id: UUID
}
