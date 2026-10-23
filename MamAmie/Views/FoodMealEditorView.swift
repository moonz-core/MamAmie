import SwiftUI
import UIKit

struct FoodMealEditorView: View {
    @ObservedObject var store: FoodDiaryStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var mealID: UUID
    @State private var loggedAt: Date
    @State private var items: [FoodMealItem]
    @State private var imageData: Data?
    @State private var note: String
    @State private var showSaved = false
    @State private var recognitionMessage: String?

    init(store: FoodDiaryStore, image: UIImage?) {
        self.store = store
        _name = State(initialValue: "Meal")
        _mealID = State(initialValue: UUID())
        _loggedAt = State(initialValue: .now)
        _items = State(initialValue: [])
        _imageData = State(initialValue: image?.jpegData(compressionQuality: 0.78))
        _note = State(initialValue: "")
    }

    init(store: FoodDiaryStore, meal: FoodMeal) {
        self.store = store
        _name = State(initialValue: meal.name)
        _mealID = State(initialValue: meal.id)
        _loggedAt = State(initialValue: meal.loggedAt)
        _items = State(initialValue: meal.items)
        _imageData = State(initialValue: meal.imageData)
        _note = State(initialValue: meal.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let imageData, let image = UIImage(data: imageData) {
                    Section {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 230)
                            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 14))
                        Label("Photo recognition isn’t connected. Identify the visible foods below; the image stays on this device.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                        Button {
                            Task {
                                do {
                                    _ = try await UnconfiguredFoodImageRecognizer().analyze(imageData: imageData)
                                } catch {
                                    recognitionMessage = error.localizedDescription
                                }
                            }
                        } label: { Label("Analyze My Meal", systemImage: "sparkles") }
                    } header: { Text("Meal photo") }
                }

                Section("Meal details") {
                    TextField("Meal name", text: $name)
                    DatePicker("Date and time", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notes or ingredients to remember", text: $note, axis: .vertical).lineLimit(2...4)
                }

                Section {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Food item (e.g. dal, roti, curd)", text: $item.name)
                                .font(.subheadline.weight(.semibold))
                            HStack {
                                Text("Portion (g)").font(.caption).foregroundStyle(.secondary)
                                TextField("grams", value: $item.portionGrams, format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                            TextField("Ingredients (if known)", text: $item.ingredients)
                                .font(.caption)
                            TextField("Preparation (if known)", text: $item.preparation)
                                .font(.caption)
                            HStack {
                                Button("Split portion") {
                                    splitItem(id: item.id)
                                }.font(.caption)
                                Spacer()
                                Button(role: .destructive) { items.removeAll { $0.id == item.id } } label: {
                                    Label("Remove", systemImage: "trash").font(.caption)
                                }
                            }
                        }.padding(.vertical, 5)
                    }
                    Button { items.append(FoodMealItem(name: "", portionGrams: 100)) } label: {
                        Label("Add food item", systemImage: "plus.circle.fill")
                    }
                } header: { Text("Foods on this plate") }

                Section {
                    Text("No verified food-composition dataset is configured. Nutrient values will show as unavailable until a reliable record is connected. Portion and ingredient details are saved so the estimate can be improved later.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("A meal photo or food diary cannot diagnose a nutrient deficiency or establish whether a diet is adequate.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Nutrition estimate") }
            }
            .navigationTitle("Review meal").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || items.isEmpty || items.contains { $0.name.trimmingCharacters(in: .whitespaces).isEmpty })
                }
            }
            .alert("Meal saved", isPresented: $showSaved) { Button("Done") { dismiss() } }
            message: { Text("Your meal is saved privately on this device. Nutrient totals remain unavailable until verified data is connected.") }
            .alert("Photo analysis unavailable", isPresented: Binding(get: { recognitionMessage != nil }, set: { if !$0 { recognitionMessage = nil } })) {
                Button("Continue manually", role: .cancel) { recognitionMessage = nil }
            } message: { Text(recognitionMessage ?? "") }
        }
    }

    private func save() {
        let meal = FoodMeal(id: mealID, name: name.trimmingCharacters(in: .whitespaces), items: items,
                            loggedAt: loggedAt, imageData: imageData, note: note)
        store.save(meal)
        showSaved = true
    }

    private func splitItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].portionGrams > 1 else { return }
        let original = items[index]
        let half = original.portionGrams / 2
        items[index].portionGrams = half
        items.append(FoodMealItem(name: original.name, portionGrams: half,
                                  ingredients: original.ingredients, preparation: original.preparation))
    }
}
