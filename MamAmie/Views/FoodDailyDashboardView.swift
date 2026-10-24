import SwiftUI
import UIKit

struct FoodDailyDashboardView: View {
    @ObservedObject var store: FoodDiaryStore
    @ObservedObject var assistantAPI: AssistantAPIClient
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

                // Visual Macronutrient Breakdown Chart
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Energy Intake")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(totals.energyKcal != nil ? "\(Int(totals.energyKcal!))" : "--")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color("AccentColor"))
                                    Text("kcal")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("Estimated from \(dayMeals.count) logged \(dayMeals.count == 1 ? "meal" : "meals")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        // Macro Distribution Bar
                        GeometryReader { geo in
                            let proteinG = totals.proteinG ?? 0
                            let carbsG = totals.carbohydrateG ?? 0
                            let fatG = totals.fatG ?? 0
                            let totalG = max(1.0, proteinG + carbsG + fatG)

                            let proteinWidth = (proteinG / totalG) * geo.size.width
                            let carbsWidth = (carbsG / totalG) * geo.size.width
                            let fatWidth = (fatG / totalG) * geo.size.width

                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.90, green: 0.28, blue: 0.42))
                                    .frame(width: max(4, proteinWidth))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.20, green: 0.60, blue: 0.86))
                                    .frame(width: max(4, carbsWidth))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.95, green: 0.65, blue: 0.25))
                                    .frame(width: max(4, fatWidth))
                            }
                        }
                        .frame(height: 12)

                        // Macro Legend Cards
                        HStack(spacing: 8) {
                            macroBadge(title: "Protein", grams: totals.proteinG, color: Color(red: 0.90, green: 0.28, blue: 0.42))
                            macroBadge(title: "Carbs", grams: totals.carbohydrateG, color: Color(red: 0.20, green: 0.60, blue: 0.86))
                            macroBadge(title: "Fat", grams: totals.fatG, color: Color(red: 0.95, green: 0.65, blue: 0.25))
                        }
                    }
                    .padding(.vertical, 4)

                    nutrientRow("Energy", totals.energyKcal, "kcal")
                    nutrientRow("Protein", totals.proteinG, "g")
                    nutrientRow("Carbohydrates", totals.carbohydrateG, "g")
                    nutrientRow("Fat", totals.fatG, "g")
                    nutrientRow("Fibre", totals.fibreG, "g")
                } header: { Text("Macronutrient balance & estimated energy") }

                Section {
                    nutrientProgressRow(name: "Iron", current: totals.ironMg, target: 27.0, unit: "mg", color: Color(red: 0.85, green: 0.30, blue: 0.35))
                    nutrientProgressRow(name: "Folate", current: totals.folateMcg, target: 400.0, unit: "mcg", color: Color(red: 0.24, green: 0.72, blue: 0.58))
                    nutrientProgressRow(name: "Calcium", current: totals.calciumMg, target: 1000.0, unit: "mg", color: Color(red: 0.38, green: 0.45, blue: 0.78))
                    nutrientProgressRow(name: "Vitamin B12", current: totals.vitaminB12Mcg, target: 2.6, unit: "mcg", color: Color(red: 0.95, green: 0.60, blue: 0.20))
                    nutrientProgressRow(name: "Vitamin D", current: totals.vitaminDMcg, target: 15.0, unit: "mcg", color: Color(red: 0.92, green: 0.75, blue: 0.20))
                } header: { Text("Maternal micronutrient target progress") }

                Section {
                    if dayMeals.isEmpty {
                        Text("No meals are recorded for this date. Missing entries do not mean you have missed nutrients.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(dayMeals) { meal in
                            NavigationLink {
                                FoodMealDetailView(meal: meal, store: store, assistantAPI: assistantAPI)
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

    @ViewBuilder private func macroBadge(title: String, grams: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }
            Text(grams != nil ? "\(Int(grams!)) g" : "--")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder private func nutrientProgressRow(name: String, current: Double?, target: Double, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let val = current {
                    let pct = Int((val / target) * 100)
                    Text("\(FoodNutritionCalculator.display(val, unit: unit)) / \(Int(target)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("(\(pct)%)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pct >= 100 ? .green : color)
                } else {
                    Text("Goal: \(Int(target)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)

                    let progress = current != nil ? min(1.0, max(0.02, current! / target)) : 0.0
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 3)
    }
}

struct FoodMealDetailView: View {
    @State var meal: FoodMeal
    @ObservedObject var store: FoodDiaryStore
    @ObservedObject var assistantAPI: AssistantAPIClient
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
            FoodMealEditorView(store: store, meal: meal, assistantAPI: assistantAPI)
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
