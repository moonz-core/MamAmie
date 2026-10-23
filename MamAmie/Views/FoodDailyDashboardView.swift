import SwiftUI
import UIKit

struct FoodDailyDashboardView: View {
    @ObservedObject var store: FoodDiaryStore
    @Environment(\.dismiss) private var dismiss
    @State private var day = Date.now

    private var dayMeals: [FoodMeal] { store.meals(on: day) }
    private var totals: FoodNutrients { FoodNutritionCalculator.sum(dayMeals.map(\.totals)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Diary date", selection: $day, displayedComponents: .date)
                    Text("\(dayMeals.count) \(dayMeals.count == 1 ? "meal" : "meals") recorded. This log may be incomplete.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Food diary") }

                Section {
                    nutrientRow("Energy", totals.energyKcal, "kcal")
                    nutrientRow("Protein", totals.proteinG, "g")
                    nutrientRow("Carbohydrates", totals.carbohydrateG, "g")
                    nutrientRow("Fat", totals.fatG, "g")
                    nutrientRow("Fibre", totals.fibreG, "g")
                } header: { Text("Estimated total from logged meals") }

                Section {
                    nutrientRow("Iron", totals.ironMg, "mg")
                    nutrientRow("Folate", totals.folateMcg, "mcg")
                    nutrientRow("Calcium", totals.calciumMg, "mg")
                    nutrientRow("Vitamin B12", totals.vitaminB12Mcg, "mcg")
                    nutrientRow("Vitamin D", totals.vitaminDMcg, "mcg")
                } header: { Text("Maternal nutrition highlights") }

                Section {
                    if dayMeals.isEmpty {
                        Text("No meals are recorded for this date. Missing entries do not mean you have missed nutrients.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(dayMeals) { meal in
                            NavigationLink {
                                FoodMealDetailView(meal: meal, store: store)
                            } label: {
                                HStack(spacing: 12) {
                                    if let data = meal.imageData, let image = UIImage(data: data) {
                                        Image(uiImage: image).resizable().scaledToFill().frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else { Image(systemName: "fork.knife.circle.fill").font(.title2).foregroundStyle(Color("AccentColor")) }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(meal.name).font(.subheadline.weight(.medium))
                                        Text(meal.loggedAt, style: .time).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }.onDelete { offsets in offsets.map { dayMeals[$0] }.forEach(store.delete) }
                    }
                } header: { Text("Meals") }

                Section {
                    Text("Nutrition values are estimates based on foods, portions, ingredients, and preparation methods identified or entered. Actual values may differ. Diary totals reflect logged meals only; there are no reference comparisons because a suitable reviewed framework is not configured. Food logs do not diagnose deficiencies.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Water intake is not included in meal totals.").font(.caption).foregroundStyle(.secondary)
                } header: { Text("About these totals") }
            }
            .navigationTitle("Daily nutrition").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    @ViewBuilder private func nutrientRow(_ title: String, _ value: Double?, _ unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(FoodNutritionCalculator.display(value, unit: unit)).foregroundStyle(value == nil ? .secondary : .primary)
        }
    }
}

struct FoodMealDetailView: View {
    @State var meal: FoodMeal
    @ObservedObject var store: FoodDiaryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEditor = false
    @State private var confirmDelete = false

    var body: some View {
        List {
            if let data = meal.imageData, let image = UIImage(data: data) {
                Section { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 260).frame(maxWidth: .infinity) }
            }
            Section("Meal") {
                Text(meal.name).font(.headline)
                LabeledContent("Logged", value: meal.loggedAt.formatted(date: .abbreviated, time: .shortened))
                if !meal.note.isEmpty { Text(meal.note) }
            }
            Section("Food items") {
                ForEach(meal.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name).font(.subheadline.weight(.semibold))
                        Text("\(item.portionGrams.formatted(.number.precision(.fractionLength(0...1)))) g · \(item.preparation)")
                            .font(.caption).foregroundStyle(.secondary)
                        if !item.ingredients.isEmpty { Text("Ingredients: \(item.ingredients)").font(.caption).foregroundStyle(.secondary) }
                    }.padding(.vertical, 3)
                }
            }
            Section("Nutrition") {
                nutrientRow("Energy", meal.totals.energyKcal, "kcal")
                nutrientRow("Protein", meal.totals.proteinG, "g")
                nutrientRow("Carbohydrates", meal.totals.carbohydrateG, "g")
                nutrientRow("Fat", meal.totals.fatG, "g")
                nutrientRow("Fibre", meal.totals.fibreG, "g")
                nutrientRow("Iron", meal.totals.ironMg, "mg")
                nutrientRow("Folate", meal.totals.folateMcg, "mcg")
                nutrientRow("Calcium", meal.totals.calciumMg, "mg")
                nutrientRow("Vitamin B12", meal.totals.vitaminB12Mcg, "mcg")
                nutrientRow("Vitamin D", meal.totals.vitaminDMcg, "mcg")
                Text("No verified food-composition record is linked to these entries yet.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("What this tells you") {
                Text("The foods and portions recorded here can help you review your eating pattern over time. This entry does not establish nutrient status or diagnose a deficiency.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section {
                Button { showEditor = true } label: { Label("Edit meal", systemImage: "pencil") }
                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete meal", systemImage: "trash") }
            }
        }
        .navigationTitle(meal.name).navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            FoodMealEditorView(store: store, meal: meal)
        }
        .confirmationDialog("Delete this meal?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete meal", role: .destructive) { store.delete(meal); dismiss() }
            Button("Cancel", role: .cancel) { }
        }
        .onReceive(store.$meals) { meals in
            if let updated = meals.first(where: { $0.id == meal.id }) { meal = updated }
        }
    }

    @ViewBuilder private func nutrientRow(_ title: String, _ value: Double?, _ unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(FoodNutritionCalculator.display(value, unit: unit)).foregroundStyle(value == nil ? .secondary : .primary)
        }
    }
}
