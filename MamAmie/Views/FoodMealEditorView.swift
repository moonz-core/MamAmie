import SwiftUI
import UIKit

struct FoodMealEditorView: View {
    @ObservedObject var store: FoodDiaryStore
    @ObservedObject var assistantAPI: AssistantAPIClient
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var mealID: UUID
    @State private var loggedAt: Date
    @State private var items: [FoodMealItem]
    @State private var imageData: Data?
    @State private var note: String
    @State private var showSaved = false
    @State private var recognitionMessage: String?
    @State private var isAnalyzing = false

    init(store: FoodDiaryStore, image: UIImage?, assistantAPI: AssistantAPIClient) {
        self.store = store
        self.assistantAPI = assistantAPI
        _name = State(initialValue: "Meal")
        _mealID = State(initialValue: UUID())
        _loggedAt = State(initialValue: .now)
        _items = State(initialValue: [])
        _imageData = State(initialValue: image?.jpegData(compressionQuality: 0.78))
        _note = State(initialValue: "")
    }

    init(store: FoodDiaryStore, meal: FoodMeal, assistantAPI: AssistantAPIClient) {
        self.store = store
        self.assistantAPI = assistantAPI
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
                        Label("Review the AI estimate carefully. The photo is sent to MamAmie’s configured AI provider for analysis.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                        Button {
                            Task {
                                isAnalyzing = true
                                defer { isAnalyzing = false }
                                do {
                                    let result = try await assistantAPI.analyzeFoodImage(imageData)
                                    items = [FoodMealItem(name: result.suggestedName, portionGrams: 100,
                                        ingredients: result.ingredients.joined(separator: ", "),
                                        preparation: result.portionDescription,
                                        nutrients: FoodNutrients(energyKcal: result.estimatedCalories,
                                            proteinG: result.estimatedProteinG, carbohydrateG: result.estimatedCarbsG,
                                            fatG: result.estimatedFatG, fibreG: result.estimatedFibreG,
                                            ironMg: result.estimatedIronMg, folateMcg: result.estimatedFolateMcg,
                                            calciumMg: result.estimatedCalciumMg, vitaminB12Mcg: nil,
                                            vitaminDMcg: nil, vitaminCMg: nil, sodiumMg: nil),
                                        dataSource: "AI estimate; review before saving")]
                                    name = result.suggestedName
                                    recognitionMessage = result.maternalSafetyNote
                                } catch {
                                    recognitionMessage = error.localizedDescription
                                }
                            }
                        } label: { Label(isAnalyzing ? "Analyzing…" : "Analyze My Meal", systemImage: "sparkles") }
                        .disabled(isAnalyzing || !assistantAPI.isSignedIn)
                        if !assistantAPI.isSignedIn {
                            Text("Sign in from the Assistant tab before analyzing a meal photo.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
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
            .alert("Review photo analysis", isPresented: Binding(get: { recognitionMessage != nil }, set: { if !$0 { recognitionMessage = nil } })) {
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
