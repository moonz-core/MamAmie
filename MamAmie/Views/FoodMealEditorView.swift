import SwiftUI
import UIKit

struct FoodMealEditorView: View {
    @ObservedObject var store: FoodDiaryStore
    var journalStore: JournalStore?
    var profile: OnboardingProfile?
    @ObservedObject var assistantAPI: AssistantAPIClient
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var mealID: UUID
    @State private var loggedAt: Date
    @State private var items: [FoodMealItem]
    @State private var imageData: Data?
    @State private var note: String
    @State private var insight: MaternalNutritionInsight?

    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showSavedAlert = false
    @State private var addedToCalendarToast = false
    @State private var addedCheckpointsToast = false

    init(
        store: FoodDiaryStore,
        image: UIImage?,
        journalStore: JournalStore? = nil,
        profile: OnboardingProfile? = nil,
        assistantAPI: AssistantAPIClient
    ) {
        self.store = store
        self.journalStore = journalStore
        self.profile = profile
        self.assistantAPI = assistantAPI
        _name = State(initialValue: "Nourishing Plate")
        _mealID = State(initialValue: UUID())
        _loggedAt = State(initialValue: .now)
        _items = State(initialValue: [])
        _imageData = State(initialValue: image?.jpegData(compressionQuality: 0.78))
        _note = State(initialValue: "")
        _insight = State(initialValue: nil)
    }

    init(
        store: FoodDiaryStore,
        meal: FoodMeal,
        journalStore: JournalStore? = nil,
        profile: OnboardingProfile? = nil,
        assistantAPI: AssistantAPIClient
    ) {
        self.store = store
        self.journalStore = journalStore
        self.profile = profile
        self.assistantAPI = assistantAPI
        _name = State(initialValue: meal.name)
        _mealID = State(initialValue: meal.id)
        _loggedAt = State(initialValue: meal.loggedAt)
        _items = State(initialValue: meal.items)
        _imageData = State(initialValue: meal.imageData)
        _note = State(initialValue: meal.note)
        _insight = State(initialValue: meal.insight)
    }

    private var currentTotals: FoodNutrients {
        FoodNutritionCalculator.sum(items.map(\.nutrients))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Meal Photo & AI Analysis Trigger
                if let imageData, let image = UIImage(data: imageData) {
                    Section {
                        VStack(spacing: 12) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Button {
                                performGeminiFoodAnalysis(data: imageData)
                            } label: {
                                HStack(spacing: 8) {
                                    if isAnalyzing {
                                        ProgressView()
                                            .tint(.white)
                                        Text("AI Analyzing Nutrients & Gaps…")
                                            .fontWeight(.semibold)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.headline)
                                        Text(items.isEmpty ? "Analyze Nutrients with Google Gemini" : "Re-Analyze with Gemini AI")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color("AccentColor"), Color.purple.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(isAnalyzing)

                            if let error = analysisError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                    } header: {
                        Text("Plate Photo")
                    }
                }

                // MARK: - Meal Overview
                Section("Meal Details") {
                    TextField("Meal name", text: $name)
                        .font(.headline)
                    DatePicker("Date and time", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notes or ingredients to remember", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                // MARK: - Pregnancy Safety Note
                if let insight = insight {
                    Section("Maternal Food Safety Assessment") {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: insight.isSafeForPregnancy ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(insight.isSafeForPregnancy ? .green : .orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.isSafeForPregnancy ? "Pregnancy Safe Choice" : "Exercise Precaution")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(insight.isSafeForPregnancy ? .green : .orange)

                                Text(insight.safetyNote)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Nutrition Breakdown (Uploaded to Screen)
                if currentTotals.energyKcal != nil || currentTotals.proteinG != nil {
                    Section("Nutrition Breakdown") {
                        // Macros Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            macroCard(title: "Calories", value: "\(Int(currentTotals.energyKcal ?? 0))", unit: "kcal", color: .orange)
                            macroCard(title: "Protein", value: String(format: "%.1f", currentTotals.proteinG ?? 0), unit: "g", color: .blue)
                            macroCard(title: "Carbs", value: String(format: "%.1f", currentTotals.carbohydrateG ?? 0), unit: "g", color: .purple)
                            macroCard(title: "Fats", value: String(format: "%.1f", currentTotals.fatG ?? 0), unit: "g", color: .mint)
                        }
                        .padding(.vertical, 4)

                        // Micronutrient Pregnancy RDA Gauges
                        VStack(spacing: 8) {
                            micronutrientRow(
                                name: "Iron",
                                value: currentTotals.ironMg,
                                unit: "mg",
                                target: MaternalFoodAIService.PregnancyRDA.ironMg,
                                color: .red
                            )
                            micronutrientRow(
                                name: "Folate / Folic Acid",
                                value: currentTotals.folateMcg,
                                unit: "mcg",
                                target: MaternalFoodAIService.PregnancyRDA.folateMcg,
                                color: .green
                            )
                            micronutrientRow(
                                name: "Calcium",
                                value: currentTotals.calciumMg,
                                unit: "mg",
                                target: MaternalFoodAIService.PregnancyRDA.calciumMg,
                                color: .indigo
                            )
                            micronutrientRow(
                                name: "Vitamin D",
                                value: currentTotals.vitaminDMcg,
                                unit: "mcg",
                                target: MaternalFoodAIService.PregnancyRDA.vitaminDMcg,
                                color: .yellow
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - AI Maternal Gap Analysis & Recommendations
                if let insight = insight {
                    Section("AI Maternal Gap Analysis") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Strengths
                            VStack(alignment: .leading, spacing: 6) {
                                Text("What this meal provided well:")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)

                                ForEach(insight.strengths, id: \.self) { strength in
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                        Text(strength)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }

                            Divider()

                            // Missing Nutrients / Gaps
                            if !insight.missingNutrients.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Missing Nutrients to Boost:")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.orange)
                                        Spacer()
                                        Text("Pregnancy Daily Target")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    ForEach(insight.missingNutrients) { gap in
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(gap.nutrientName)
                                                    .font(.subheadline.weight(.semibold))
                                                Spacer()
                                                Text("\(gap.amountInMeal) / \(gap.dailyTarget)")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text(gap.whyBabyNeedsIt)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color.orange.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Suggested Foods
                    if !insight.suggestedFoods.isEmpty {
                        Section("Recommended Foods for Missing Nutrients") {
                            ForEach(insight.suggestedFoods) { food in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(food.foodName)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(food.richIn)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color("AccentColor"))
                                    }
                                    Text(food.portionTip)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }

                    // Suggested Supplements to Buy
                    if !insight.suggestedSupplements.isEmpty {
                        Section("Recommended Supplements to Buy") {
                            ForEach(insight.suggestedSupplements) { supp in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top) {
                                        Image(systemName: "pill.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.purple)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(supp.supplementName)
                                                .font(.subheadline.weight(.bold))
                                            Text(supp.purpose)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    HStack {
                                        Text("Dosage:")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        Text(supp.dosageTip)
                                            .font(.caption2)
                                    }

                                    HStack {
                                        Text("Buying advice:")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.purple)
                                        Text(supp.buyingAdvice)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // Calendar Integration Buttons
                    Section("Calendar Tracking") {
                        if let journalStore = journalStore {
                            Button {
                                addMealToCalendarAction(journalStore: journalStore, insight: insight)
                            } label: {
                                HStack {
                                    Image(systemName: addedToCalendarToast ? "checkmark.circle.fill" : "calendar.badge.plus")
                                        .font(.headline)
                                    Text(addedToCalendarToast ? "Added to Calendar!" : "Add Meal & Nutrients to Calendar Page")
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(addedToCalendarToast ? .green : Color("AccentColor"))
                            }

                            if !insight.suggestedSupplements.isEmpty || !insight.suggestedFoods.isEmpty {
                                Button {
                                    addCheckpointsAction(journalStore: journalStore, insight: insight)
                                } label: {
                                    HStack {
                                        Image(systemName: addedCheckpointsToast ? "checkmark.circle.fill" : "checklist")
                                            .font(.headline)
                                        Text(addedCheckpointsToast ? "Added to Daily Checkpoints!" : "Add Supplements to Daily Calendar Checkpoints")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(addedCheckpointsToast ? .green : .purple)
                                }
                            }
                        }
                    }
                }

                // MARK: - Food Items Breakdown
                Section("Plate Food Items") {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Food item", text: $item.name)
                                .font(.subheadline.weight(.semibold))

                            HStack {
                                Text("Portion:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("grams", value: $item.portionGrams, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.caption)
                                Text("g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !item.ingredients.isEmpty {
                                Text("Ingredients: \(item.ingredients)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        items.append(FoodMealItem(name: "", portionGrams: 100))
                    } label: {
                        Label("Add Food Item Manually", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Review & Analyze Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Meal") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || items.isEmpty)
                }
            }
            .alert("Meal Saved", isPresented: $showSavedAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your meal and comprehensive maternal nutrient analysis are saved.")
            }
            .onAppear {
                // Auto-analyze on initial appearance if photo exists and items are empty
                if items.isEmpty, let data = imageData {
                    performGeminiFoodAnalysis(data: data)
                }
            }
        }
    }

    // MARK: - Actions
    private func performGeminiFoodAnalysis(data: Data) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisError = nil

        Task {
            do {
                let (mealItem, analysisInsight) = try await MaternalFoodAIService.shared.analyzeMealPhoto(
                    imageData: data,
                    profile: profile
                )

                await MainActor.run {
                    self.items = [mealItem]
                    self.name = mealItem.name
                    self.insight = analysisInsight
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.analysisError = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }

    private func addMealToCalendarAction(journalStore: JournalStore, insight: MaternalNutritionInsight) {
        let meal = FoodMeal(
            id: mealID,
            name: name.trimmingCharacters(in: .whitespaces),
            items: items,
            loggedAt: loggedAt,
            imageData: imageData,
            note: note,
            insight: insight
        )

        _ = MaternalFoodAIService.shared.addMealToCalendar(
            store: journalStore,
            meal: meal,
            insight: insight,
            date: loggedAt
        )

        withAnimation {
            addedToCalendarToast = true
        }
    }

    private func addCheckpointsAction(journalStore: JournalStore, insight: MaternalNutritionInsight) {
        MaternalFoodAIService.shared.addRecommendationsToCheckpoints(
            store: journalStore,
            date: loggedAt,
            supplements: insight.suggestedSupplements,
            foods: insight.suggestedFoods
        )

        withAnimation {
            addedCheckpointsToast = true
        }
    }

    private func save() {
        let meal = FoodMeal(
            id: mealID,
            name: name.trimmingCharacters(in: .whitespaces),
            items: items,
            loggedAt: loggedAt,
            imageData: imageData,
            note: note,
            insight: insight
        )
        store.save(meal)

        // Automatically sync to calendar as well if journalStore is connected
        if let journalStore = journalStore, let insight = insight {
            _ = MaternalFoodAIService.shared.addMealToCalendar(
                store: journalStore,
                meal: meal,
                insight: insight,
                date: loggedAt
            )
        }

        showSavedAlert = true
    }

    // MARK: - UI Subviews
    private func macroCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func micronutrientRow(name: String, value: Double?, unit: String, target: Double, color: Color) -> some View {
        let val = value ?? 0
        let percentage = min(1.0, val / target)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(val < 10 ? String(format: "%.1f", val) : "\(Int(val))") / \(Int(target)) \(unit)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("(\(Int(percentage * 100))%)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(percentage)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
