import Foundation

/// Nutrients are optional so an unknown value is never confused with zero.
struct FoodNutrients: Codable, Equatable {
    var energyKcal: Double?
    var proteinG: Double?
    var carbohydrateG: Double?
    var fatG: Double?
    var fibreG: Double?
    var ironMg: Double?
    var folateMcg: Double?
    var calciumMg: Double?
    var vitaminB12Mcg: Double?
    var vitaminDMcg: Double?
    var vitaminCMg: Double?
    var sodiumMg: Double?
    var dhaMg: Double?
    var cholineMg: Double?

    static let unavailable = FoodNutrients()
}

struct FoodMealItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var portionGrams: Double
    var ingredients: String = ""
    var preparation: String = "Not recorded"
    /// Values describe this item's full portion. Nil fields remain unavailable.
    var nutrients: FoodNutrients = .unavailable
    var dataSource: String = "No verified food-composition record configured"
}

struct MaternalNutritionInsight: Codable, Equatable, Identifiable {
    var id = UUID()
    var mealName: String
    var strengths: [String]
    var missingNutrients: [MaternalNutrientGap]
    var suggestedFoods: [MaternalFoodSuggestion]
    var suggestedSupplements: [MaternalSupplementSuggestion]
    var clinicalGuidance: String
    var isSafeForPregnancy: Bool
    var safetyNote: String
}

struct MaternalNutrientGap: Codable, Equatable, Identifiable {
    var id: String { nutrientName }
    var nutrientName: String
    var amountInMeal: String
    var dailyTarget: String
    var urgencyLevel: String // "Moderate" or "High Priority"
    var whyBabyNeedsIt: String
}

struct MaternalFoodSuggestion: Codable, Equatable, Identifiable {
    var id = UUID()
    var foodName: String
    var richIn: String
    var portionTip: String
}

struct MaternalSupplementSuggestion: Codable, Equatable, Identifiable {
    var id = UUID()
    var supplementName: String
    var dosageTip: String
    var purpose: String
    var whyItIsGood: String = ""
    var buyingAdvice: String
}

struct FoodMeal: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var items: [FoodMealItem]
    var loggedAt = Date()
    var imageData: Data?
    var note: String = ""
    var insight: MaternalNutritionInsight? = nil

    var totals: FoodNutrients { FoodNutritionCalculator.sum(items.map(\.nutrients)) }
}

enum FoodNutritionCalculator {
    static func sum(_ values: [FoodNutrients]) -> FoodNutrients {
        func total(_ keyPath: KeyPath<FoodNutrients, Double?>) -> Double? {
            let available = values.compactMap { $0[keyPath: keyPath] }
            // A partial sum would understate the meal when any item lacks this nutrient.
            guard !available.isEmpty, available.count == values.count else { return nil }
            return available.reduce(0, +)
        }
        return FoodNutrients(
            energyKcal: total(\.energyKcal), proteinG: total(\.proteinG),
            carbohydrateG: total(\.carbohydrateG), fatG: total(\.fatG),
            fibreG: total(\.fibreG), ironMg: total(\.ironMg),
            folateMcg: total(\.folateMcg), calciumMg: total(\.calciumMg),
            vitaminB12Mcg: total(\.vitaminB12Mcg), vitaminDMcg: total(\.vitaminDMcg),
            vitaminCMg: total(\.vitaminCMg), sodiumMg: total(\.sodiumMg),
            dhaMg: total(\.dhaMg), cholineMg: total(\.cholineMg)
        )
    }

    static func display(_ value: Double?, unit: String) -> String {
        guard let value else { return "Data unavailable" }
        let rounded = value < 10 ? (value * 10).rounded() / 10 : value.rounded()
        return "\(rounded) \(unit)"
    }
}
