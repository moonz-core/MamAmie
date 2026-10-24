import Foundation

/// Small on-device early warning screen. It is a demo aid, not clinically reviewed.
enum AssistantSafetyScreening {
    static func emergencyMessage(for input: String) -> String? {
        let text = input.lowercased()
        let reported = ["i have", "i am", "i'm", "i feel", "i noticed", "my headache", "my pain", "my bleeding", "my symptoms", "my baby", "experiencing", "right now"]
            .contains { text.contains($0) }
        let questionOnly = text.hasPrefix("i have a question") || text.hasPrefix("i have question")
        let hypothetical = ["if i have ", "if i had ", "if my ", "what if i have ", "what if i had ", "what if my ", "suppose i have ", "suppose my ", "hypothetically"]
            .contains { text.contains($0) }
        guard reported && !questionOnly && !hypothetical else { return nil }
        let clauses = text.replacingOccurrences(of: "however", with: "but")
            .components(separatedBy: CharacterSet(charactersIn: ".,;!?\n"))
            .flatMap { $0.components(separatedBy: " but ") }
        let breathingTerms = ["can't breathe", "cannot breathe", "difficulty breathing", "trouble breathing", "severe shortness of breath", "gasping"]
        let chestTerms = ["chest pain", "chest tightness", "pain in my chest"]
        let bleedingTerms = ["vaginal bleeding", "bleeding", "bleedin", "bleedng", "heavy bleeding", "spotting"]
        let seizureTerms = ["seizure", "convulsion", "having a fit", "fainted", "passed out", "unconscious"]
        let severePainTerms = ["severe abdominal pain", "severe belly pain", "severe stomach pain", "unbearable abdominal pain"]
        let headacheTerms = ["severe headache", "sudden headache"]
        let visionTerms = ["blurred vision", "blurry vision", "seeing spots", "flashing lights"]
        let movementTerms = ["baby hasn't moved", "baby has not moved", "baby is not moving", "not feeling baby move", "reduced fetal movement", "no fetal movement", "decreased fetal movement"]
        let selfHarmTerms = ["suicidal", "kill myself", "hurt myself", "self-harm", "harm my baby"]
        let denial = #"(?i)(?:i don't have|i do not have|i'm not|i am not|i haven't had|i have no|no|not having|not experiencing|without)(?:\s+(?:my|any|a|the|vaginal|heavy|severe|chest|abdominal|belly|stomach|fetal|blurred|blurry|vision|short|of|breath|pain|headache|bleeding|movement|having|experiencing)){0,5}\s*$"#

        func asserted(_ terms: [String], in clause: String) -> Bool {
            for term in terms {
                guard let range = clause.range(of: term) else { continue }
                let prefix = String(clause[..<range.lowerBound])
                if prefix.range(of: denial, options: .regularExpression) == nil { return true }
            }
            return false
        }

        let hasEmergency = clauses.contains { clause in
            asserted(breathingTerms, in: clause) || asserted(chestTerms, in: clause) ||
            asserted(bleedingTerms, in: clause) || asserted(seizureTerms, in: clause) ||
            asserted(severePainTerms, in: clause) || asserted(movementTerms, in: clause) ||
            asserted(selfHarmTerms, in: clause) ||
            (asserted(headacheTerms, in: clause) && asserted(visionTerms, in: clause))
        }
        guard hasEmergency else { return nil }
        return "A symptom you described may need urgent assessment. Don’t wait for an app response. Contact your maternity team or go to the nearest emergency department now. If you are in India, call 112; elsewhere contact local emergency services. Ask someone you trust to stay with you if possible. This on-device warning screen is not a complete or clinically reviewed protocol."
    }
}
