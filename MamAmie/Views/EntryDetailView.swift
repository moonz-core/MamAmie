import SwiftUI

struct EntryDetailView: View {
    @ObservedObject var store: JournalStore
    let entryID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var attachmentToRemove: AttachmentReference?

    private var entry: CalendarEntry? {
        store.entry(id: entryID)
    }

    var body: some View {
        Group {
            if let entry {
                detailScrollView(for: entry)
                    .navigationTitle(entry.category.shortName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { entryToolbar }
                    .sheet(isPresented: $showingEditor) {
                        NavigationStack {
                            EntryEditorView(
                                store: store,
                                category: entry.category,
                                existingEntry: entry,
                                initialDate: LocalDay.date(from: entry.dayKey) ?? Date()
                            ) {
                                showingEditor = false
                            }
                        }
                    }
                    .confirmationDialog(
                        "Delete this entry?",
                        isPresented: $showingDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            if store.deleteEntry(id: entryID) {
                                dismiss()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This removes the entry and any private attachments linked to it.")
                    }
                    .confirmationDialog(
                        "Remove this attachment?",
                        isPresented: Binding(
                            get: { attachmentToRemove != nil },
                            set: { if !$0 { attachmentToRemove = nil } }
                        ),
                        titleVisibility: .visible
                    ) {
                        Button("Remove", role: .destructive) {
                            if let attachmentToRemove {
                                _ = store.removeAttachment(
                                    entryID: entryID,
                                    attachmentID: attachmentToRemove.id
                                )
                            }
                            self.attachmentToRemove = nil
                        }
                        Button("Cancel", role: .cancel) { attachmentToRemove = nil }
                    }
            } else {
                unavailableState
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
    }

    private func detailScrollView(for entry: CalendarEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                EntryDetailHeader(entry: entry)
                EntryDetailContentView(store: store, entry: entry)
                AttachmentListView(
                    entry: entry,
                    store: store,
                    onRemove: { attachmentToRemove = $0 }
                )
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
    }

    @ToolbarContentBuilder
    private var entryToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete entry", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Entry actions")
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Entry unavailable")
                .font(.headline)
            Text("This entry may have been removed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
