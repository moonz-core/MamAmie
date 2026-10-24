import Combine
import Foundation

struct FoodRecognitionResult {
    var items: [FoodMealItem]
}

/// Integration boundary for a future reviewed, server-hosted image model.
/// API credentials and meal images must not be embedded in this iOS client.
protocol FoodImageUnderstanding {
    func analyze(imageData: Data) async throws -> FoodRecognitionResult
}

struct UnconfiguredFoodImageRecognizer: FoodImageUnderstanding {
    enum RecognitionError: LocalizedError {
        case notConfigured
        var errorDescription: String? { "Photo recognition is not connected yet. You can still enter the foods and portions yourself." }
    }

    func analyze(imageData: Data) async throws -> FoodRecognitionResult {
        throw RecognitionError.notConfigured
    }
}

/// Private, on-device food diary. Image analysis is intentionally not faked.
final class FoodDiaryStore: ObservableObject {
    @Published private(set) var meals: [FoodMeal] = []
    @Published var errorMessage: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        let directory = storageURL ?? ((try? fileManager.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)) ?? fileManager.temporaryDirectory)
            .appendingPathComponent("MamAmie", isDirectory: true)
        fileURL = directory.appendingPathComponent("food-diary.json")
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: fileURL.path) {
                meals = try JSONDecoder().decode([FoodMeal].self, from: Data(contentsOf: fileURL))
                    .sorted { $0.loggedAt > $1.loggedAt }
            }
        } catch {
            errorMessage = "Your saved meals could not be loaded. You can still add a meal."
        }
    }

    func save(_ meal: FoodMeal) {
        var updated = meals
        if let index = updated.firstIndex(where: { $0.id == meal.id }) { updated[index] = meal }
        else { updated.insert(meal, at: 0) }
        persist(updated)
    }

    func delete(_ meal: FoodMeal) { persist(meals.filter { $0.id != meal.id }) }

    func reset() {
        meals = []
        try? FileManager.default.removeItem(at: fileURL)
        errorMessage = nil
    }

    func meals(on date: Date = .now, calendar: Calendar = .current) -> [FoodMeal] {
        meals.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
    }

    func reset() {
        meals = []
        try? FileManager.default.removeItem(at: fileURL)
        errorMessage = nil
    }

    private func persist(_ updated: [FoodMeal]) {
        do {
            let data = try JSONEncoder().encode(updated)
            try data.write(to: fileURL, options: .atomic)
            meals = updated.sorted { $0.loggedAt > $1.loggedAt }
            errorMessage = nil
        } catch {
            errorMessage = "This meal could not be saved. Your changes are still on screen."
        }
    }
}
