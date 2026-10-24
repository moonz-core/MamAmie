import Foundation

struct AIExerciseAdaptationResult: Identifiable, Equatable {
    let id = UUID()
    let observation: String
    let adaptedExercises: [String]
    let coachAffirmation: String
}

final class AIExerciseAdaptationService {
    static let shared = AIExerciseAdaptationService()

    func evaluateAndAdapt(
        store: JournalStore,
        profile: OnboardingProfile?,
        todayKey: String
    ) async -> AIExerciseAdaptationResult? {
        let calendar = LocalDay.calendar
        guard let todayDate = LocalDay.date(from: todayKey) else { return nil }

        // Inspect the last 5 days
        var skippedExerciseCount = 0
        var recentMoods: [String] = []

        for offset in 1...5 {
            guard let pastDate = calendar.date(byAdding: .day, value: -offset, to: todayDate) else { continue }
            let pastKey = LocalDay.key(for: pastDate)
            let entries = store.entries(for: pastKey)

            for entry in entries {
                if entry.category == .task {
                    let lower = entry.title.lowercased()
                    if lower.contains("walk") || lower.contains("step") || lower.contains("yoga") || lower.contains("exercise") {
                        if entry.task?.completed != true {
                            skippedExerciseCount += 1
                        }
                    }
                } else if entry.category == .journal {
                    if let mood = entry.journal?.mood, !mood.isEmpty {
                        recentMoods.append(mood)
                    }
                }
            }
        }

        // Also check today's mood
        let todaysMood = store.entries(for: todayKey)
            .first(where: { $0.category == .journal })?.journal?.mood

        let isFatiguedOrSkipping = skippedExerciseCount >= 1 ||
            todaysMood?.lowercased() == "tired" ||
            todaysMood?.lowercased() == "nauseous" ||
            todaysMood?.lowercased() == "anxious"

        guard isFatiguedOrSkipping else { return nil }

        let week = profile?.gestationalWeek ?? 20
        let moodText = todaysMood ?? recentMoods.first ?? "Fatigued"

        // Call Gemini via GeminiChatService
        let systemPrompt = """
        You are an empathetic, expert prenatal movement and maternal wellness AI coach.
        An expectant mother is feeling fatigued or has skipped several walking/exercise sessions.
        Output ONLY a JSON object with this exact structure:
        {
          "observation": "1 gentle, compassionate sentence acknowledging her fatigue or skipped workouts without any guilt.",
          "adaptedExercises": [
            "1 gentle, seated or restorative 5-minute exercise tailored to her stage",
            "1 relaxing, zero-strain breathing or stretching exercise"
          ],
          "coachAffirmation": "1 warm sentence reminding her that rest and gentle movement are both triumphs."
        }
        """

        let userPrompt = "Pregnant at Week \(week). Recent mood: \(moodText). Skipped exercises in recent days: \(skippedExerciseCount)."

        do {
            let response = try await GeminiChatService.shared.generateFeatureCompletion(
                systemInstruction: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.6,
                fallbackText: Self.offlineFallbackJSON(week: week)
            )

            if let parsed = Self.parseJSON(response) {
                return parsed
            }
        } catch {
            // Safe fallback
        }

        return Self.defaultFallback(week: week, mood: moodText)
    }

    private static func parseJSON(_ text: String) -> AIExerciseAdaptationResult? {
        let clean = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let observation = json["observation"] as? String,
              let exercises = json["adaptedExercises"] as? [String],
              let affirmation = json["coachAffirmation"] as? String else {
            return nil
        }

        return AIExerciseAdaptationResult(
            observation: observation,
            adaptedExercises: exercises,
            coachAffirmation: affirmation
        )
    }

    private static func offlineFallbackJSON(week: Int) -> String {
        """
        {
          "observation": "We noticed your body has needed extra rest recently at Week \(week) — growing a baby is demanding full-time work.",
          "adaptedExercises": [
            "5-minute Seated Pelvic Tilts on a soft chair or yoga ball",
            "Restorative 10-minute Legs-Elevated breathing & gentle neck release"
          ],
          "coachAffirmation": "Listening to your body is the highest form of maternal wellness."
        }
        """
    }

    private static func defaultFallback(week: Int, mood: String) -> AIExerciseAdaptationResult {
        AIExerciseAdaptationResult(
            observation: "We noticed walking felt a bit too demanding recently. Let's adapt today's plan to meet your energy right where you are.",
            adaptedExercises: [
                "5-min Seated Gentle Pelvic Tilts on a comfortable chair",
                "10-min Restorative Leg Elevation with slow abdominal breathing"
            ],
            coachAffirmation: "Honoring your rest is just as important as movement. Be gentle with yourself today, Mama."
        )
    }
}
