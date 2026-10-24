import Combine
import Foundation
import SwiftUI

struct GeminiChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date
    var isEmergency: Bool
    var emergencyAction: String?
    var isPending: Bool

    enum Role: String, Codable {
        case user
        case model
        case system
    }

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date(),
        isEmergency: Bool = false,
        emergencyAction: String? = nil,
        isPending: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.isEmergency = isEmergency
        self.emergencyAction = emergencyAction
        self.isPending = isPending
    }
}

struct MaternalContextSnapshot: Equatable {
    let stageName: String
    let gestationalWeekText: String?
    let dueDateText: String?
    let lmpText: String?
    let daysRemainingText: String?
    let todaysMealCount: Int
    let todaysCaloriesText: String?
    let todaysKeyNutrientsSummary: String?
    let fullContextString: String
}

@MainActor
final class GeminiChatService: ObservableObject {
    static let shared = GeminiChatService()

    @Published var messages: [GeminiChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var lastErrorMessage: String?
    @Published var activeApiKey: String = ""

    private let userDefaultsKey = "mamamie_gemini_api_key"
    private let chatHistoryDefaultsKey = "mamamie_gemini_chat_history"

    init() {
        loadApiKey()
        loadHistory()
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }

    var hasApiKey: Bool {
        !activeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        activeApiKey = trimmed
        UserDefaults.standard.set(trimmed, forKey: userDefaultsKey)
    }

    func clearApiKey() {
        activeApiKey = ""
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private(set) var isLoadedFromEnvironment: Bool = false

    func refreshApiKey() {
        loadApiKey()
    }

    private func loadApiKey() {
        // 1. Process environment variables (Xcode Scheme, system environment, launch arguments)
        let envVarNames = [
            "GEMINI_API_KEY",
            "GOOGLE_API_KEY",
            "GEMINI_KEY",
            "AI_KEY",
            "GOOGLE_GEMINI_API_KEY"
        ]
        for name in envVarNames {
            if let val = ProcessInfo.processInfo.environment[name],
               !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                activeApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
                isLoadedFromEnvironment = true
                return
            }
        }

        // 2. Info.plist / Bundle variables
        if let plistVal = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !plistVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            activeApiKey = plistVal.trimmingCharacters(in: .whitespacesAndNewlines)
            isLoadedFromEnvironment = true
            return
        }

        // 3. User-entered key stored in UserDefaults
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            activeApiKey = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            isLoadedFromEnvironment = false
            return
        }

        // 4. Static configuration in APIConfiguration.swift
        if !APIConfiguration.geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            activeApiKey = APIConfiguration.geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            isLoadedFromEnvironment = false
            return
        }

        isLoadedFromEnvironment = false
    }

    func clearHistory() {
        messages = []
        UserDefaults.standard.removeObject(forKey: chatHistoryDefaultsKey)
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcome = GeminiChatMessage(
            role: .model,
            text: "Hello, Mama! 💕 I'm **MamAmie**, your dedicated maternal wellness companion. I stay continuously aware of your pregnancy dates and what you eat throughout the day. Ask me anything about nutrition, symptoms, or how your baby is developing!"
        )
        messages.append(welcome)
    }

    // MARK: - Context Generation

    func buildContextSnapshot(profile: OnboardingProfile?, meals: [FoodMeal]) -> MaternalContextSnapshot {
        let calendar = Calendar.current
        let today = Date()

        // 1. Stage and Pregnancy Dates
        var stageTitle = "Pregnancy Care"
        if let stage = profile?.stage {
            stageTitle = stage.title
        }

        var weekText: String? = nil
        if let week = profile?.gestationalWeek {
            let trimester: String
            switch week {
            case 0...13: trimester = "1st Trimester"
            case 14...27: trimester = "2nd Trimester"
            default: trimester = "3rd Trimester"
            }
            weekText = "Week \(week) (\(trimester))"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        var dueText: String? = nil
        var daysRemainingText: String? = nil
        if let dueDate = profile?.dueDate {
            dueText = dateFormatter.string(from: dueDate)
            let days = calendar.dateComponents([.day], from: today, to: dueDate).day ?? 0
            if days > 0 {
                daysRemainingText = "\(days) days to due date"
            }
        }

        var lmpText: String? = nil
        if let lmp = profile?.lastPeriodDate {
            lmpText = dateFormatter.string(from: lmp)
        }

        // 2. Food Intake (Today and recent 48 hours)
        let todaysMeals = meals.filter { calendar.isDateInToday($0.loggedAt) }
        let mealCount = todaysMeals.count

        var caloriesText: String? = nil
        var keyNutrientsText: String? = nil

        if !todaysMeals.isEmpty {
            let totalCalories = todaysMeals.compactMap { $0.totals.energyKcal }.reduce(0, +)
            let totalProtein = todaysMeals.compactMap { $0.totals.proteinG }.reduce(0, +)
            let totalIron = todaysMeals.compactMap { $0.totals.ironMg }.reduce(0, +)
            let totalCalcium = todaysMeals.compactMap { $0.totals.calciumMg }.reduce(0, +)
            let totalFolate = todaysMeals.compactMap { $0.totals.folateMcg }.reduce(0, +)

            if totalCalories > 0 {
                caloriesText = "\(Int(totalCalories)) kcal"
            }

            var nutrients: [String] = []
            if totalProtein > 0 { nutrients.append("\(String(format: "%.1f", totalProtein))g protein") }
            if totalIron > 0 { nutrients.append("\(String(format: "%.1f", totalIron))mg iron") }
            if totalCalcium > 0 { nutrients.append("\(Int(totalCalcium))mg calcium") }
            if totalFolate > 0 { nutrients.append("\(Int(totalFolate))mcg folate") }
            if !nutrients.isEmpty {
                keyNutrientsText = nutrients.joined(separator: ", ")
            }
        }

        // 3. Assemble Full System Context String
        var fullText = "=== USER'S LIVE MATERNAL CONTEXT ===\n"
        let userName = (profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? profile!.displayName : "Mama"
        fullText += "Mother's Name: \(userName)\n"
        fullText += "Care Stage: \(stageTitle)\n"
        if let weekText { fullText += "Gestational Age: \(weekText)\n" }
        if let dueText { fullText += "Due Date (EDD): \(dueText)\(daysRemainingText != nil ? " (\(daysRemainingText!))" : "")\n" }
        if let lmpText { fullText += "Last Menstrual Period (LMP): \(lmpText)\n" }

        if let conditions = profile?.medicalConditions, !conditions.isEmpty {
            fullText += "Medical Conditions: \(conditions.joined(separator: ", "))\n"
        }
        if let allergies = profile?.allergies, !allergies.isEmpty {
            fullText += "Allergies: \(allergies.joined(separator: ", "))\n"
        }
        if let meds = profile?.medicationsAndSupplements, !meds.isEmpty {
            fullText += "Current Medications & Supplements: \(meds.joined(separator: ", "))\n"
        }
        if let diet = profile?.dietaryPreference {
            fullText += "Dietary Preference: \(diet.title)\n"
        }

        fullText += "\n=== RECENT FOOD INTAKE & NUTRITION ===\n"
        if todaysMeals.isEmpty {
            fullText += "No meals logged yet today.\n"
        } else {
            fullText += "Meals Logged Today (\(todaysMeals.count) total):\n"
            let timeFmt = DateFormatter()
            timeFmt.timeStyle = .short
            for meal in todaysMeals.sorted(by: { $0.loggedAt > $1.loggedAt }) {
                var mealLine = "• [\(timeFmt.string(from: meal.loggedAt))] \(meal.name)"
                let itemsList = meal.items.map { item in
                    var desc = "\(item.name) (\(Int(item.portionGrams))g)"
                    if let cal = item.nutrients.energyKcal { desc += " - \(Int(cal)) kcal" }
                    if let iron = item.nutrients.ironMg, iron > 0 { desc += ", \(String(format: "%.1f", iron))mg iron" }
                    return desc
                }.joined(separator: ", ")
                if !itemsList.isEmpty { mealLine += ": \(itemsList)" }
                if !meal.note.isEmpty { mealLine += " (Note: \(meal.note))" }
                fullText += mealLine + "\n"
            }
            if let cal = caloriesText {
                fullText += "Today's Totals: \(cal)"
                if let nut = keyNutrientsText { fullText += " | \(nut)" }
                fullText += "\n"
            }
        }

        // Include yesterday's meals for broader nutrition picture
        let yesterdaysMeals = meals.filter {
            let days = calendar.dateComponents([.day], from: $0.loggedAt, to: today).day ?? 0
            return days == 1
        }
        if !yesterdaysMeals.isEmpty {
            fullText += "\nYesterday's Logged Meals (\(yesterdaysMeals.count)):\n"
            for meal in yesterdaysMeals.prefix(3) {
                let itemsList = meal.items.map(\.name).joined(separator: ", ")
                fullText += "• \(meal.name): \(itemsList)\n"
            }
        }

        return MaternalContextSnapshot(
            stageName: stageTitle,
            gestationalWeekText: weekText,
            dueDateText: dueText,
            lmpText: lmpText,
            daysRemainingText: daysRemainingText,
            todaysMealCount: mealCount,
            todaysCaloriesText: caloriesText,
            todaysKeyNutrientsSummary: keyNutrientsText,
            fullContextString: fullText
        )
    }

    // MARK: - Sending Messages

    func sendMessage(
        _ text: String,
        profile: OnboardingProfile?,
        meals: [FoodMeal]
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }

        // Local Emergency Screening
        let emergencyWarning = AssistantSafetyScreening.emergencyMessage(for: trimmed)
        let isEmergency = emergencyWarning != nil

        // Add user message to thread
        let userMessage = GeminiChatMessage(
            role: .user,
            text: trimmed,
            isEmergency: isEmergency,
            emergencyAction: emergencyWarning
        )
        messages.append(userMessage)

        // If local emergency warning triggers, display safety card directly
        if let warning = emergencyWarning {
            let safetyResponse = GeminiChatMessage(
                role: .model,
                text: "⚠️ **URGENT MEDICAL ASSESSMENT NEEDED**\n\n\(warning)\n\nPlease contact your obstetrician, midwife, or visit the nearest emergency maternity ward immediately.",
                isEmergency: true,
                emergencyAction: warning
            )
            messages.append(safetyResponse)
            saveHistory()
            return
        }

        guard hasApiKey else {
            let noKeyResponse = GeminiChatMessage(
                role: .model,
                text: "✨ **Gemini API Key Required**\n\nTo power your personalized maternal AI companion, please configure your Gemini API Key in the settings menu above.\n\nYou can generate a free Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey) in under a minute!"
            )
            messages.append(noKeyResponse)
            saveHistory()
            return
        }

        // Add pending assistant placeholder
        let pendingMessage = GeminiChatMessage(
            role: .model,
            text: "",
            isPending: true
        )
        messages.append(pendingMessage)
        isGenerating = true
        lastErrorMessage = nil

        let snapshot = buildContextSnapshot(profile: profile, meals: meals)

        do {
            let responseText = try await callGeminiAPI(
                userPrompt: trimmed,
                contextSnapshot: snapshot,
                conversationHistory: messages.dropLast() // exclude pending placeholder
            )

            // Update pending placeholder with model response
            if let index = messages.firstIndex(where: { $0.id == pendingMessage.id }) {
                messages[index].text = responseText
                messages[index].isPending = false
            }
            saveHistory()
        } catch {
            let errorDesc = error.localizedDescription
            lastErrorMessage = errorDesc
            if let index = messages.firstIndex(where: { $0.id == pendingMessage.id }) {
                messages[index].text = "I encountered an issue connecting to Gemini: \(errorDesc).\n\nPlease verify your API key or internet connection and try again."
                messages[index].isPending = false
            }
            saveHistory()
        }

        isGenerating = false
    }

    // MARK: - Gemini REST API Call

    private func callGeminiAPI(
        userPrompt: String,
        contextSnapshot: MaternalContextSnapshot,
        conversationHistory: [GeminiChatMessage]
    ) async throws -> String {
        let primaryModel = "gemini-1.5-flash"
        let fallbackModel = "gemini-2.0-flash"

        do {
            return try await executeGeminiRequest(
                model: primaryModel,
                userPrompt: userPrompt,
                contextSnapshot: contextSnapshot,
                conversationHistory: conversationHistory
            )
        } catch {
            // Attempt fallback to gemini-2.0-flash
            return try await executeGeminiRequest(
                model: fallbackModel,
                userPrompt: userPrompt,
                contextSnapshot: contextSnapshot,
                conversationHistory: conversationHistory
            )
        }
    }

    private func executeGeminiRequest(
        model: String,
        userPrompt: String,
        contextSnapshot: MaternalContextSnapshot,
        conversationHistory: [GeminiChatMessage]
    ) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(activeApiKey)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // System Instruction with strict maternal grounding and live context
        let systemInstructionText = """
        You are MamAmie, an empathetic, warm, and medically grounded maternal health and wellness AI companion.
        You are conversing with an expectant or postpartum mother.

        \(contextSnapshot.fullContextString)

        CRITICAL CLINICAL & PERSONALIZATION GUIDELINES:
        1. LIVE CONTEXT AWARENESS: Always pay close attention to her specific pregnancy timeline (gestational week, trimester, due date, LMP) and her recent food logs (calories, iron, protein, calcium, etc.). Whenever her question touches on nutrition, symptoms, energy, or fetal growth, explicitly link your answer to her current week and what she has eaten recently!
        2. NUTRITION GUIDANCE: For diet or meal questions, actively recommend foods that complement what she has already logged today (e.g., if she logged low iron or high carbs, suggest iron-rich spinach/lentils or protein pairings).
        3. RED FLAGS & SAFETY: If the user describes emergency symptoms (heavy bleeding, severe abdominal pain, visual changes, severe persistent headache, sudden swelling of face/hands, leakage of fluid, or decreased fetal movement), immediately advise her to contact her doctor, midwife, or maternity emergency room immediately.
        4. TONE: Warm, reassuring, uplifting, evidence-based, and easy to understand.
        """

        // Build conversation turns (last 10 turns to avoid token overflow)
        var contents: [[String: Any]] = []
        let historySubset = conversationHistory.suffix(10)
        for msg in historySubset {
            guard !msg.isPending, !msg.text.isEmpty else { continue }
            let roleString = (msg.role == .user) ? "user" : "model"
            contents.append([
                "role": roleString,
                "parts": [["text": msg.text]]
            ])
        }

        // Add current user prompt
        contents.append([
            "role": "user",
            "parts": [["text": userPrompt]]
        ])

        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemInstructionText]]
            ],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let errorMessage = errorObj["message"] as? String {
                throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "GeminiAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned HTTP \(httpResponse.statusCode)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Malformed response format from Gemini API"])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - API Key Verification

    func testApiKey(_ key: String) async -> (success: Bool, message: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (false, "API key cannot be empty.")
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(trimmed)") else {
            return (false, "Invalid URL structure.")
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": "Hello, respond with 'OK'."]]]
            ]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                return (true, "Key successfully verified with Gemini 1.5 Flash ✨")
            } else {
                if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errObj = errJson["error"] as? [String: Any],
                   let msg = errObj["message"] as? String {
                    return (false, msg)
                }
                return (false, "Verification failed with status code \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Persistence

    private func saveHistory() {
        let nonPending = messages.filter { !$0.isPending }
        if let encoded = try? JSONEncoder().encode(nonPending) {
            UserDefaults.standard.set(encoded, forKey: chatHistoryDefaultsKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: chatHistoryDefaultsKey),
           let decoded = try? JSONDecoder().decode([GeminiChatMessage].self, from: data),
           !decoded.isEmpty {
            messages = decoded
        }
    }
}
