import PhotosUI
import SwiftUI
import UIKit

struct EntryEditorView: View {
    @ObservedObject var store: JournalStore
    let category: EntryCategory
    let existingEntry: CalendarEntry?
    let initialDate: Date
    let onSaved: () -> Void

    @State var form: EntryFormState
    @State var selectedPhotoItem: PhotosPickerItem?
    @State var selectedPhotoData: Data?
    @State var photoPreviewID = UUID()
    @State var showValidationMessage = false
    @State var photoErrorMessage: String?

    init(
        store: JournalStore,
        category: EntryCategory,
        existingEntry: CalendarEntry? = nil,
        initialDate: Date = Date(),
        onSaved: @escaping () -> Void = {}
    ) {
        self.store = store
        self.category = category
        self.existingEntry = existingEntry
        self.initialDate = initialDate
        self.onSaved = onSaved
        _form = State(initialValue: EntryFormState(
            entry: existingEntry,
            store: store,
            fallbackDate: initialDate
        ))
    }

    var body: some View {
        Form {
            dateSection
            categoryFields
            attachmentSection
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existingEntry == nil ? "New \(category.shortName)" : "Edit \(category.shortName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: save)
                    .fontWeight(.semibold)
            }
        }
        .alert("Add a little more detail", isPresented: $showValidationMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .alert(
            "Couldn't add that photo",
            isPresented: Binding(
                get: { photoErrorMessage != nil },
                set: { if !$0 { photoErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { photoErrorMessage = nil }
        } message: {
            Text(photoErrorMessage ?? "Please choose a different image.")
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    private var validationMessage: String {
        if form.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please add a title so you can recognize this entry later."
        }
        if category == .photo && selectedPhotoData == nil && existingEntry?.attachments.isEmpty != false {
            return "Choose a photo before saving a photograph entry."
        }
        return "Please review the entry and try again."
    }

    private func save() {
        guard form.isValid else {
            showValidationMessage = true
            return
        }

        let now = Date()
        let entry = form.makeEntry(
            category: category,
            existingEntry: existingEntry,
            now: now
        )
        let schedule = medicationSchedule(for: entry, now: now)

        if store.upsertEntry(
            entry,
            medicationSchedule: schedule,
            attachmentData: selectedPhotoData
        ) {
            onSaved()
        }
    }

    private func medicationSchedule(for entry: CalendarEntry, now: Date) -> MedicationSchedule? {
        guard category == .medication, let medicationID = entry.medicationID else {
            return nil
        }

        return MedicationSchedule(
            id: medicationID,
            sourceEntryID: entry.id,
            name: form.title.trimmingCharacters(in: .whitespacesAndNewlines),
            dose: form.dose,
            instructions: form.instructions,
            recurrence: form.recurrence,
            createdAt: existingEntry.flatMap { store.medicationSchedule(for: $0)?.createdAt } ?? now,
            modifiedAt: now
        )
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                photoErrorMessage = "That image could not be read. Please choose a different image."
                return
            }
            guard data.count <= 20 * 1024 * 1024 else {
                selectedPhotoData = nil
                photoErrorMessage = "That image is larger than 20 MB. Please choose a smaller image."
                return
            }
            selectedPhotoData = data
            photoPreviewID = UUID()
        } catch {
            selectedPhotoData = nil
            photoErrorMessage = "That image could not be imported. Please try again."
        }
    }
}
