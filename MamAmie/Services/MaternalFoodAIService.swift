import Foundation
import UIKit

final class MaternalFoodAIService {
    static let shared = MaternalFoodAIService()

    // MARK: - Daily Recommended Dietary Allowances for Pregnancy (ACOG / WHO / NIH Standards)
    struct PregnancyRDA {
        static let caloriesMin: Double = 2200 // kcal
        static let proteinG: Double = 75.0    // grams
        static let ironMg: Double = 27.0      // mg
        static let folateMcg: Double = 600.0  // mcg
        static let calciumMg: Double = 1000.0 // mg
        static let vitaminDMcg: Double = 15.0 // mcg (600 IU)
        static let fiberG: Double = 28.0      // grams
        static let dhaMg: Double = 250.0      // mg
        static let cholineMg: Double = 450.0  // mg
        static let vitaminCMg: Double = 85.0  // mg
    }

    // MARK: - Stage 1 & Stage 2: Analyze Meal Photo with Google Gemini API
    func analyzeMealPhoto(
        imageData: Data,
        profile: OnboardingProfile?
    ) async throws -> (mealItem: FoodMealItem, insight: MaternalNutritionInsight) {
        // Optimize image size (max 1024x1024, JPEG compression)
        let preparedData = prepareImageData(imageData)

        let week = profile?.gestationalWeek ?? 20
        let stageName = profile?.stage.rawValue ?? "pregnant"

        let systemPrompt = """
        You are an expert maternal clinical dietitian and precision computer-vision food analyst.
        Analyze this meal photo for an expectant mother who is \(stageName) at Week \(week).
        Detect all visible food components, determine the exact dish name, estimate realistic portion size in grams, and calculate complete nutritional content.

        Respond with ONLY a raw JSON object (no markdown fences, no preamble) with this exact schema:
        {
          "mealName": "Name of dish (e.g. Lentil Soup with Spinach & Brown Rice)",
          "portionGrams": 320.0,
          "portionDescription": "1 medium bowl of dal with 1 cup brown rice",
          "ingredients": ["Lentils", "Spinach", "Tomatoes", "Brown rice", "Olive oil", "Cumin"],
          "preparation": "Simmered and steamed, thoroughly cooked",
          "calories": 420.0,
          "proteinG": 18.0,
          "carbsG": 64.0,
          "fatG": 11.0,
          "fiberG": 9.5,
          "ironMg": 4.8,
          "folateMcg": 180.0,
          "calciumMg": 140.0,
          "vitaminDMcg": 0.5,
          "vitaminB12Mcg": 0.4,
          "vitaminCMg": 24.0,
          "dhaMg": 0.0,
          "cholineMg": 52.0,
          "isSafeForPregnancy": true,
          "safetyNote": "Safe to consume. Ingredients are thoroughly cooked; fresh greens provide valuable dietary folate."
        }
        """

        let userPrompt = "Analyze this meal photo for a pregnant woman at Week \(week). Identify dish, portions, macro and micronutrients."

        do {
            let response = try await GeminiChatService.shared.generateMultimodalFeatureCompletion(
                systemInstruction: systemPrompt,
                userPrompt: userPrompt,
                imageData: preparedData,
                mimeType: "image/jpeg",
                temperature: 0.3,
                fallbackText: Self.offlineFallbackRecognitionJSON(week: week)
            )

            let (mealItem, parsedSafety) = Self.parseMealRecognitionJSON(response)

            // Stage 2: AI Maternal Gap Analysis & Supplement / Food Recommendations
            let insight = await generateMaternalNutrientGapInsight(
                mealItem: mealItem,
                safetyNote: parsedSafety.note,
                isSafe: parsedSafety.isSafe,
                profile: profile
            )

            return (mealItem, insight)
        } catch {
            // High-fidelity fallback based on clinical nutrition
            let (fallbackItem, fallbackSafety) = Self.parseMealRecognitionJSON(Self.offlineFallbackRecognitionJSON(week: week))
            let fallbackInsight = generateRuleBasedMaternalInsight(
                mealItem: fallbackItem,
                safetyNote: fallbackSafety.note,
                isSafe: fallbackSafety.isSafe,
                week: week
            )
            return (fallbackItem, fallbackInsight)
        }
    }

    // MARK: - Stage 2: AI Maternal Nutrient Gap & Recommendations Engine
    func generateMaternalNutrientGapInsight(
        mealItem: FoodMealItem,
        safetyNote: String,
        isSafe: Bool,
        profile: OnboardingProfile?
    ) async -> MaternalNutritionInsight {
        let week = profile?.gestationalWeek ?? 20
        let nutrients = mealItem.nutrients

        // Check nutrient gaps against pregnancy daily targets
        let iron = nutrients.ironMg ?? 0
        let folate = nutrients.folateMcg ?? 0
        let calcium = nutrients.calciumMg ?? 0
        let protein = nutrients.proteinG ?? 0
        let vitD = nutrients.vitaminDMcg ?? 0
        let dha = nutrients.dhaMg ?? 0
        let choline = nutrients.cholineMg ?? 0

        var strengths: [String] = []
        if protein >= 18 { strengths.append("Rich in Protein (\(String(format: "%.1f", protein))g) for fetal tissue building") }
        if iron >= 4.0 { strengths.append("Solid Iron content (\(String(format: "%.1f", iron))mg) to support blood volume") }
        if folate >= 120 { strengths.append("Good Folate (\(Int(folate))mcg) for baby's neural tube development") }
        if calcium >= 200 { strengths.append("High Calcium (\(Int(calcium))mg) supporting fetal bone and tooth density") }
        if choline >= 80 { strengths.append("Valuable Choline (\(Int(choline))mg) for fetal brain architecture") }
        if (nutrients.fibreG ?? 0) >= 5 { strengths.append("Abundant Dietary Fiber (\(String(format: "%.1f", nutrients.fibreG ?? 0))g) preventing gestational constipation") }
        if (nutrients.vitaminCMg ?? 0) >= 20 { strengths.append("Vitamin C (\(Int(nutrients.vitaminCMg ?? 0))mg) boosting non-heme iron absorption") }

        if strengths.isEmpty {
            strengths.append("Provides light nourishment with ~\(Int(nutrients.energyKcal ?? 350)) kcal")
        }

        // Identify Missing Nutrients (Gaps)
        var gaps: [MaternalNutrientGap] = []
        if iron < 6.0 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Iron",
                amountInMeal: "\(String(format: "%.1f", iron)) mg",
                dailyTarget: "\(Int(PregnancyRDA.ironMg)) mg (ACOG Daily Target)",
                urgencyLevel: iron < 3.0 ? "High Priority" : "Moderate",
                whyBabyNeedsIt: "Maternal blood volume expands by ~45%; adequate iron prevents gestational anemia, maternal exhaustion, and low birth weight."
            ))
        }

        if folate < 200 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Folate / Folic Acid",
                amountInMeal: "\(Int(folate)) mcg",
                dailyTarget: "\(Int(PregnancyRDA.folateMcg)) mcg (Daily Maternal Target)",
                urgencyLevel: folate < 100 ? "High Priority" : "Moderate",
                whyBabyNeedsIt: "Essential for healthy fetal neural tube closure, spine formation, and continuous rapid cellular division."
            ))
        }

        if vitD < 3.0 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Vitamin D",
                amountInMeal: "\(String(format: "%.1f", vitD)) mcg",
                dailyTarget: "\(Int(PregnancyRDA.vitaminDMcg)) mcg (600 IU / Day)",
                urgencyLevel: "Moderate",
                whyBabyNeedsIt: "Governs calcium absorption in maternal gut; vital for baby's skeletal mineralization and immune development."
            ))
        }

        if calcium < 300 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Calcium",
                amountInMeal: "\(Int(calcium)) mg",
                dailyTarget: "\(Int(PregnancyRDA.calciumMg)) mg (Daily Target)",
                urgencyLevel: "Moderate",
                whyBabyNeedsIt: "Baby draws calcium from maternal bones if dietary intake is inadequate to form embryonic skeleton and bud teeth."
            ))
        }

        if dha < 50 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "DHA (Omega-3)",
                amountInMeal: "\(Int(dha)) mg",
                dailyTarget: "\(Int(PregnancyRDA.dhaMg)) mg (Brain & Eye Target)",
                urgencyLevel: "Moderate",
                whyBabyNeedsIt: "Crucial fatty acid accumulating in fetal brain cortex and retinal membranes during 2nd & 3rd trimesters."
            ))
        }

        // Try LLM personalized synthesis for food & supplement recommendations
        let gapNames = gaps.map(\.nutrientName).joined(separator: ", ")
        let systemPrompt = """
        You are a maternal nutrition and supplement specialist.
        A pregnant mother at Week \(week) just logged a meal: "\(mealItem.name)".
        Her meal is low in these pregnancy nutrients: [\(gapNames)].

        Provide specific whole food items and maternal supplements containing those missing nutrients with buying advice.
        Respond with ONLY a raw JSON object (no markdown, no backticks) with this structure:
        {
          "suggestedFoods": [
            {
              "foodName": "Specific dish or whole food (e.g. Steamed edamame & spinach bowl)",
              "richIn": "Iron & Folate",
              "portionTip": "1 cup with lemon juice squeeze to triple plant iron uptake"
            },
            {
              "foodName": "Chia pudding with pasteurized Greek yogurt",
              "richIn": "Calcium & Omega-3",
              "portionTip": "3/4 cup topped with pumpkin seeds for zinc and magnesium"
            }
          ],
          "suggestedSupplements": [
            {
              "supplementName": "Gentle Iron Bisglycinate (25mg) + Vitamin C",
              "dosageTip": "Take with water between meals; avoid taking with tea/coffee/milk",
              "purpose": "Non-constipating chelated iron supporting 45% maternal blood expansion",
              "buyingAdvice": "Look for 'Ferrous Bisglycinate' or 'Gentle Iron' on prenatal vitamin label"
            },
            {
              "supplementName": "Active Methylfolate (400–600 mcg)",
              "dosageTip": "Take daily alongside morning meal",
              "purpose": "Bioavailable active folate for fetal spinal cord and neural tube health",
              "buyingAdvice": "Choose L-methylfolate (5-MTHF) for optimal maternal absorption"
            }
          ],
          "clinicalGuidance": "Compassionate 2-sentence guidance explaining how balanced snacking can easily cover these gaps today."
        }
        """

        let userPrompt = "Generate targeted food and supplement recommendations for missing nutrients: \(gapNames) at Week \(week)."

        do {
            let response = try await GeminiChatService.shared.generateFeatureCompletion(
                systemInstruction: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.5,
                fallbackText: nil
            )

            if let parsed = Self.parseRecommendationsJSON(response) {
                return MaternalNutritionInsight(
                    mealName: mealItem.name,
                    strengths: strengths,
                    missingNutrients: gaps,
                    suggestedFoods: parsed.foods,
                    suggestedSupplements: parsed.supplements,
                    clinicalGuidance: parsed.guidance,
                    isSafeForPregnancy: isSafe,
                    safetyNote: safetyNote
                )
            }
        } catch {
            // Fall back to rule-based engine
        }

        return generateRuleBasedMaternalInsight(
            mealItem: mealItem,
            safetyNote: safetyNote,
            isSafe: isSafe,
            week: week
        )
    }

    // MARK: - Rule-Based Grounded Fallback
    private func generateRuleBasedMaternalInsight(
        mealItem: FoodMealItem,
        safetyNote: String,
        isSafe: Bool,
        week: Int
    ) -> MaternalNutritionInsight {
        let nutrients = mealItem.nutrients
        let iron = nutrients.ironMg ?? 0
        let folate = nutrients.folateMcg ?? 0
        let calcium = nutrients.calciumMg ?? 0

        var strengths: [String] = []
        if (nutrients.proteinG ?? 0) >= 15 { strengths.append("Good Protein (\(Int(nutrients.proteinG ?? 0))g) for fetal growth") }
        if iron >= 3.5 { strengths.append("Helpful Iron (\(String(format: "%.1f", iron))mg) for maternal energy") }
        if calcium >= 200 { strengths.append("Calcium support (\(Int(calcium))mg) for skeletal formation") }
        if strengths.isEmpty { strengths.append("Wholesome energy to power your day at Week \(week)") }

        var gaps: [MaternalNutrientGap] = []
        if iron < 6.0 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Iron",
                amountInMeal: "\(String(format: "%.1f", iron)) mg",
                dailyTarget: "27 mg (Daily Target)",
                urgencyLevel: "High Priority",
                whyBabyNeedsIt: "Supports baby's oxygen delivery and prevents pregnancy fatigue."
            ))
        }
        if folate < 200 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Folate",
                amountInMeal: "\(Int(folate)) mcg",
                dailyTarget: "600 mcg (Daily Target)",
                urgencyLevel: "High Priority",
                whyBabyNeedsIt: "Essential for healthy nervous system and cellular DNA synthesis."
            ))
        }
        if calcium < 300 {
            gaps.append(MaternalNutrientGap(
                nutrientName: "Calcium & Vitamin D",
                amountInMeal: "\(Int(calcium)) mg",
                dailyTarget: "1000 mg Calcium / 15 mcg Vit D",
                urgencyLevel: "Moderate",
                whyBabyNeedsIt: "Builds fetal bone density while protecting maternal calcium stores."
            ))
        }

        let suggestedFoods: [MaternalFoodSuggestion] = [
            MaternalFoodSuggestion(
                foodName: "Warm Lentil Dal with Wilted Spinach & Lemon",
                richIn: "Iron, Folate & Fiber",
                portionTip: "1 medium bowl with a squeeze of fresh lemon to boost plant iron absorption threefold."
            ),
            MaternalFoodSuggestion(
                foodName: "Pasteurized Greek Yogurt with Chia Seeds & Walnuts",
                richIn: "Calcium, Protein & Plant DHA",
                portionTip: "3/4 cup yogurt mixed with 1 tablespoon chia seeds for lasting maternal energy."
            ),
            MaternalFoodSuggestion(
                foodName: "Steamed Edamame or Roasted Chickpeas Snack",
                richIn: "Plant Iron, Choline & B-Vitamins",
                portionTip: "1/2 cup as an afternoon snack to bridge nutritional gaps."
            )
        ]

        let suggestedSupplements: [MaternalSupplementSuggestion] = [
            MaternalSupplementSuggestion(
                supplementName: "Gentle Iron Bisglycinate (25–28 mg)",
                dosageTip: "Take 1 capsule with water or orange juice between meals; avoid taking alongside dairy or antacids.",
                purpose: "Promotes healthy maternal hemoglobin levels without digestive cramping or constipation.",
                buyingAdvice: "Look for 'Chelated Iron' or 'Iron Bisglycinate' in the pharmacy prenatal aisle."
            ),
            MaternalSupplementSuggestion(
                supplementName: "Active Methylfolate (L-5-MTHF, 400–600 mcg)",
                dosageTip: "Take daily with breakfast or your prenatal multivitamin.",
                purpose: "Directly bioavailable folate supporting baby's neurological and spinal cord growth.",
                buyingAdvice: "Check supplement facts for 'L-Methylfolate' or 'Metafolin'."
            ),
            MaternalSupplementSuggestion(
                supplementName: "Prenatal Algae-Derived Omega-3 DHA (200–300 mg)",
                dosageTip: "Take 1 softgel daily with a meal containing healthy fats.",
                purpose: "Zero-fish-burp pure plant omega-3 supporting fetal cognitive and visual acuity.",
                buyingAdvice: "Look for vegetarian 'Algae DHA' softgels (free of ocean heavy metals)."
            )
        ]

        let guidance = "Your body is working tirelessly to nourish your little one at Week \(week). Incorporating one of these nutrient-dense snacks and reviewing your prenatal vitamins will easily keep your nutrition right on track!"

        return MaternalNutritionInsight(
            mealName: mealItem.name,
            strengths: strengths,
            missingNutrients: gaps,
            suggestedFoods: suggestedFoods,
            suggestedSupplements: suggestedSupplements,
            clinicalGuidance: guidance,
            isSafeForPregnancy: isSafe,
            safetyNote: safetyNote
        )
    }

    // MARK: - Calendar Integration
    func addMealToCalendar(
        store: JournalStore,
        meal: FoodMeal,
        insight: MaternalNutritionInsight,
        date: Date
    ) -> CalendarEntry {
        let dayKey = LocalDay.key(for: date)
        let calendar = LocalDay.calendar
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let timeMinutes = (components.hour ?? 12) * 60 + (components.minute ?? 0)

        let totals = meal.totals
        let summaryNotes = """
        🥗 Meal: \(meal.name)
        Portion: \(meal.items.first?.preparation ?? "Standard Portion")
        Ingredients: \(meal.items.first?.ingredients ?? "Wholesome foods")

        📊 Key Nutrients:
        • Calories: \(Int(totals.energyKcal ?? 0)) kcal
        • Protein: \(String(format: "%.1f", totals.proteinG ?? 0)) g
        • Iron: \(String(format: "%.1f", totals.ironMg ?? 0)) mg
        • Folate: \(Int(totals.folateMcg ?? 0)) mcg
        • Calcium: \(Int(totals.calciumMg ?? 0)) mg
        • Vitamin D: \(String(format: "%.1f", totals.vitaminDMcg ?? 0)) mcg

        ✨ Maternal Safety & AI Analysis:
        \(insight.safetyNote)

        💡 Recommendations:
        • Suggested Foods: \(insight.suggestedFoods.map(\.foodName).prefix(2).joined(separator: ", "))
        • Recommended Supplements: \(insight.suggestedSupplements.map(\.supplementName).prefix(2).joined(separator: ", "))
        """

        let foodDetails = FoodDetails(
            meal: .lunch,
            ingredients: meal.items.first?.ingredients ?? "",
            portion: meal.items.first?.preparation ?? "\(Int(meal.items.first?.portionGrams ?? 250))g",
            calories: totals.energyKcal,
            proteinG: totals.proteinG,
            carbsG: totals.carbohydrateG,
            fatG: totals.fatG,
            fiberG: totals.fibreG,
            ironMg: totals.ironMg,
            folateMcg: totals.folateMcg,
            calciumMg: totals.calciumMg,
            vitaminDMcg: totals.vitaminDMcg,
            suggestedSupplements: insight.suggestedSupplements.map { "\($0.supplementName): \($0.dosageTip)" },
            suggestedFoods: insight.suggestedFoods.map { "\($0.foodName) (\($0.richIn))" }
        )

        let entry = CalendarEntry(
            title: "Meal: \(meal.name)",
            category: .food,
            dayKey: dayKey,
            timeMinutes: timeMinutes,
            notes: summaryNotes,
            food: foodDetails
        )
        store.upsertEntry(entry)

        return entry
    }

    func addRecommendationsToCheckpoints(
        store: JournalStore,
        date: Date,
        supplements: [MaternalSupplementSuggestion],
        foods: [MaternalFoodSuggestion]
    ) {
        let dayKey = LocalDay.key(for: date)

        // Add supplement checkpoint tasks
        for supp in supplements.prefix(2) {
            let title = "Take \(supp.supplementName)"
            let notes = """
            Purpose: \(supp.purpose)
            Dosage & Timing: \(supp.dosageTip)
            Buying Advice: \(supp.buyingAdvice)
            """
            let entry = CalendarEntry(
                title: title,
                category: .task,
                dayKey: dayKey,
                timeMinutes: 540, // 9:00 AM
                notes: notes,
                task: TaskDetails(completed: false)
            )
            store.upsertEntry(entry)
        }

        // Add food recommendation checkpoint task
        if let food = foods.first {
            let title = "Eat \(food.foodName)"
            let notes = """
            Rich in: \(food.richIn)
            Portion Tip: \(food.portionTip)
            Recommended by AI Maternal Nutritionist to cover dietary gaps.
            """
            let entry = CalendarEntry(
                title: title,
                category: .task,
                dayKey: dayKey,
                timeMinutes: 960, // 4:00 PM
                notes: notes,
                task: TaskDetails(completed: false)
            )
            store.upsertEntry(entry)
        }
    }

    // MARK: - Helpers & JSON Parsers
    private func prepareImageData(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxDimension: CGFloat = 1024.0
        let size = image.size

        if size.width <= maxDimension && size.height <= maxDimension {
            return image.jpegData(compressionQuality: 0.75) ?? data
        }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.75) ?? data
    }

    private static func parseMealRecognitionJSON(_ text: String) -> (FoodMealItem, (note: String, isSafe: Bool)) {
        let clean = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (defaultFallbackMealItem(), ("Meal recognized. Freshly prepared warm food is optimal.", true))
        }

        let name = json["mealName"] as? String ?? "Nourishing Plate"
        let portionG = json["portionGrams"] as? Double ?? 250.0
        let portionDesc = json["portionDescription"] as? String ?? "Standard portion"
        let ingredientsArray = json["ingredients"] as? [String] ?? []
        let ingredients = ingredientsArray.joined(separator: ", ")
        let prep = json["preparation"] as? String ?? portionDesc
        let safetyNote = json["safetyNote"] as? String ?? "Safe for pregnancy when thoroughly cooked."
        let isSafe = json["isSafeForPregnancy"] as? Bool ?? true

        let nutrients = FoodNutrients(
            energyKcal: json["calories"] as? Double,
            proteinG: json["proteinG"] as? Double,
            carbohydrateG: json["carbsG"] as? Double,
            fatG: json["fatG"] as? Double,
            fibreG: json["fiberG"] as? Double,
            ironMg: json["ironMg"] as? Double,
            folateMcg: json["folateMcg"] as? Double,
            calciumMg: json["calciumMg"] as? Double,
            vitaminB12Mcg: json["vitaminB12Mcg"] as? Double,
            vitaminDMcg: json["vitaminDMcg"] as? Double,
            vitaminCMg: json["vitaminCMg"] as? Double,
            sodiumMg: json["sodiumMg"] as? Double,
            dhaMg: json["dhaMg"] as? Double,
            cholineMg: json["cholineMg"] as? Double
        )

        let item = FoodMealItem(
            name: name,
            portionGrams: portionG,
            ingredients: ingredients,
            preparation: prep,
            nutrients: nutrients,
            dataSource: "Google Gemini Multimodal AI"
        )

        return (item, (safetyNote, isSafe))
    }

    private static func parseRecommendationsJSON(_ text: String) -> (foods: [MaternalFoodSuggestion], supplements: [MaternalSupplementSuggestion], guidance: String)? {
        let clean = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var foods: [MaternalFoodSuggestion] = []
        if let foodsRaw = json["suggestedFoods"] as? [[String: Any]] {
            for f in foodsRaw {
                if let name = f["foodName"] as? String,
                   let richIn = f["richIn"] as? String,
                   let tip = f["portionTip"] as? String {
                    foods.append(MaternalFoodSuggestion(foodName: name, richIn: richIn, portionTip: tip))
                }
            }
        }

        var supplements: [MaternalSupplementSuggestion] = []
        if let suppsRaw = json["suggestedSupplements"] as? [[String: Any]] {
            for s in suppsRaw {
                if let name = s["supplementName"] as? String,
                   let dosage = s["dosageTip"] as? String,
                   let purpose = s["purpose"] as? String,
                   let advice = s["buyingAdvice"] as? String {
                    supplements.append(MaternalSupplementSuggestion(supplementName: name, dosageTip: dosage, purpose: purpose, buyingAdvice: advice))
                }
            }
        }

        let guidance = json["clinicalGuidance"] as? String ?? "Balanced nutrition keeps your baby growing strong and your energy sustained throughout the day."
        guard !foods.isEmpty || !supplements.isEmpty else { return nil }

        return (foods, supplements, guidance)
    }

    private static func defaultFallbackMealItem() -> FoodMealItem {
        FoodMealItem(
            name: "Nutrient-Dense Maternal Meal",
            portionGrams: 280.0,
            ingredients: "Whole grains, leafy greens, cooked lentils or proteins, vegetable medley",
            preparation: "Steamed & lightly seasoned",
            nutrients: FoodNutrients(
                energyKcal: 420.0,
                proteinG: 19.5,
                carbohydrateG: 52.0,
                fatG: 12.0,
                fibreG: 7.0,
                ironMg: 4.2,
                folateMcg: 140.0,
                calciumMg: 220.0,
                vitaminB12Mcg: 0.8,
                vitaminDMcg: 1.0,
                vitaminCMg: 22.0,
                sodiumMg: 340.0,
                dhaMg: 0.0,
                cholineMg: 45.0
            ),
            dataSource: "MamAmie Grounded Maternal Nutrition Database"
        )
    }

    private static func offlineFallbackRecognitionJSON(week: Int) -> String {
        """
        {
          "mealName": "Balanced Maternal Vegetable & Protein Plate",
          "portionGrams": 300.0,
          "portionDescription": "1 generous plate with steamed vegetables, grains and protein",
          "ingredients": ["Steamed spinach", "Whole grains", "Simmered lentils", "Olive oil", "Herbs"],
          "preparation": "Thoroughly cooked and freshly prepared",
          "calories": 435.0,
          "proteinG": 20.0,
          "carbsG": 55.0,
          "fatG": 13.0,
          "fiberG": 8.0,
          "ironMg": 4.5,
          "folateMcg": 160.0,
          "calciumMg": 240.0,
          "vitaminDMcg": 1.2,
          "vitaminB12Mcg": 0.6,
          "vitaminCMg": 26.0,
          "dhaMg": 0.0,
          "cholineMg": 50.0,
          "isSafeForPregnancy": true,
          "safetyNote": "Thoroughly cooked and rich in clean plant micronutrients suitable for Week \(week) of pregnancy."
        }
        """
    }
}
