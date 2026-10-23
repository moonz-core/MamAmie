import SwiftUI

struct AddEntrySheet: View {
    @ObservedObject var store: JournalStore
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: EntryCategory?

    var body: some View {
        NavigationStack {
            Group {
                if let selectedCategory {
                    EntryEditorView(store: store, category: selectedCategory, initialDate: date) {
                        dismiss()
                    }
                } else {
                    EntryCategoryListView { selectedCategory = $0 }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                if selectedCategory != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            selectedCategory = nil
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Choose a different entry type")
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var navigationTitle: String {
        if let selectedCategory {
            return selectedCategory.shortName
        }
        return "Add to \(LocalDay.dateText(for: LocalDay.key(for: date)))"
    }
}

private struct EntryCategoryListView: View {
    let onSelect: (EntryCategory) -> Void

    var body: some View {
        List {
            Section {
                Text("Choose what you would like to remember. You can add details without completing every field.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 14, trailing: 0))
            }

            ForEach(EntryCategory.allCases) { category in
                Button {
                    onSelect(category)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: category.systemImage)
                            .foregroundStyle(Color("AccentColor"))
                            .frame(width: 38, height: 38)
                            .background(Color("AccentColor").opacity(0.11))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.displayName)
                                .foregroundStyle(.primary)
                                .font(.subheadline.weight(.semibold))
                            Text(categoryDescription(for: category))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func categoryDescription(for category: EntryCategory) -> String {
        switch category {
        case .medication: return "Keep instructions and dose history together."
        case .appointment: return "Save care visits, questions, and status."
        case .test: return "Record tests, reports, and follow-up dates."
        case .symptom: return "Capture how you felt, without judgment."
        case .food: return "Remember meals, ingredients, and notes."
        case .journal: return "Write a private note for this day."
        case .photo: return "Keep a private photo with a memory."
        case .milestone: return "Mark an event that matters to you."
        case .task: return "Plan something for this day."
        }
    }
}
