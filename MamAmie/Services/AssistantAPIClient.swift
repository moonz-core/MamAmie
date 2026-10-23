import Combine
import Foundation
import Security

struct AssistantCitation: Decodable, Identifiable {
    var citationId: String
    var sourceId: String?
    var title: String
    var issuingOrganization: String
    var source: String
    var originalUrl: String?
    var section: String?
    var pageNumber: Int?
    var publicationDate: String?
    var lastReviewedDate: String?
    var reviewStatus: String
    var summary: String
    var id: String { citationId }
}

struct AssistantAIResponse: Decodable {
    var answer: String
    var citations: [AssistantCitation]
    var safetyEscalation: Bool
    var emergencyNotice: String?
    var safetyLevel: String
    var safetyMessage: String?
    var requiresProfessionalReview: Bool
    var retrievalStatus: String
    var evidenceSufficient: Bool
    var generationMode: String
    var limitations: [String]
    var disclaimer: String
}

struct FoodImageAnalysisResponse: Decodable {
    var suggestedName: String
    var confidence: Double
    var ingredients: [String]
    var portionDescription: String
    var estimatedCalories: Double
    var estimatedProteinG: Double
    var estimatedCarbsG: Double
    var estimatedFatG: Double
    var estimatedIronMg: Double
    var estimatedFolateMcg: Double
    var estimatedCalciumMg: Double?
    var estimatedFibreG: Double?
    var maternalSafetyNote: String
    var isEstimate: Bool
}

private struct AssistantTokens: Codable {
    var accessToken: String
    var refreshToken: String
}

private struct TokenResponse: Decodable {
    var accessToken: String
    var refreshToken: String
}

private struct RegisterResponse: Decodable {
    var id: String
}

enum AssistantAPIError: LocalizedError {
    case invalidServer
    case notSignedIn
    case sessionExpired
    case unavailable
    case rejected

    var errorDescription: String? {
        switch self {
        case .invalidServer: return "Enter a valid HTTPS MamAmie server address."
        case .notSignedIn: return "Sign in to use the assistant."
        case .sessionExpired: return "Your session expired. Please sign in again."
        case .unavailable: return "MamAmie could not reach the server. Check the server address and connection, then try again."
        case .rejected: return "The server could not complete that request. Please review the information and try again."
        }
    }
}

@MainActor
final class AssistantAPIClient: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var isBusy = false
    @Published var serverAddress: String {
        didSet { UserDefaults.standard.set(serverAddress, forKey: "mamamie.assistant.server") }
    }
    @Published private(set) var userEmail = ""

    private let keychainService = "com.mamamie.app.assistant"
    private let keychainAccount = "session-tokens"
    private var tokens: AssistantTokens?

    init() {
        serverAddress = UserDefaults.standard.string(forKey: "mamamie.assistant.server") ?? APIConfiguration.productionBaseURL.absoluteString
        tokens = readTokens()
        isSignedIn = tokens != nil
    }

    func registerAndSignIn(name: String, email: String, password: String) async throws {
        isBusy = true
        defer { isBusy = false }
        try await validateServer()
        let _: RegisterResponse = try await send(path: "/api/v1/auth/register", body: [
            "email": email, "password": password, "full_name": name,
        ], authenticated: false)
        try await signIn(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        isBusy = true
        defer { isBusy = false }
        try await validateServer()
        let response: TokenResponse = try await send(path: "/api/v1/auth/login", body: [
            "email": email, "password": password,
        ], authenticated: false)
        tokens = AssistantTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        userEmail = email
        saveTokens()
        isSignedIn = true
    }

    func signOut() {
        tokens = nil
        userEmail = ""
        isSignedIn = false
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: keychainService,
                       kSecAttrAccount: keychainAccount] as CFDictionary)
    }

    func ask(_ query: String, stage: String, externalConsent: Bool) async throws -> AssistantAIResponse {
        try await send(path: "/api/v1/ai-assistant/query", body: [
            "query": query, "stage": stage, "language": "en",
            "consent_to_external_processing": externalConsent,
        ])
    }

    func triage(_ symptoms: String, stage: String) async throws -> AssistantAIResponse {
        try await send(path: "/api/v1/ai-assistant/triage", body: [
            "symptoms": symptoms, "stage": stage, "language": "en",
        ])
    }

    func explainReport(_ text: String, question: String, stage: String, externalConsent: Bool) async throws -> AssistantAIResponse {
        try await send(path: "/api/v1/ai-assistant/reports/explain", body: [
            "report_text": text, "question": question, "stage": stage,
            "consent_to_external_processing": externalConsent,
        ])
    }

    func analyzeFoodImage(_ imageData: Data) async throws -> FoodImageAnalysisResponse {
        guard let token = tokens?.accessToken else { throw AssistantAPIError.notSignedIn }
        guard let base = URL(string: serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)), base.scheme == "https", let host = base.host else { throw AssistantAPIError.invalidServer }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        let prefix = base.path.hasSuffix("/") ? String(base.path.dropLast()) : base.path
        components?.path = prefix + "/nutrition/analyze-image"
        guard let url = components?.url, url.host == host else { throw AssistantAPIError.invalidServer }
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8))
        body.append(imageData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AssistantAPIError.unavailable }
            if http.statusCode == 401 { signOut(); throw AssistantAPIError.sessionExpired }
            guard (200..<300).contains(http.statusCode) else { throw AssistantAPIError.rejected }
            let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(FoodImageAnalysisResponse.self, from: data)
        } catch let error as AssistantAPIError { throw error }
        catch { throw AssistantAPIError.unavailable }
    }

    private func validateServer() async throws {
        guard let url = URL(string: serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", url.host != nil else { throw AssistantAPIError.invalidServer }
    }

    private func send<Response: Decodable>(path: String, body: [String: Any], authenticated: Bool = true,
                                           retryAuthentication: Bool = true) async throws -> Response {
        guard let base = URL(string: serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)),
              base.scheme == "https", let host = base.host,
              base.user == nil, base.password == nil, base.query == nil, base.fragment == nil else {
            throw AssistantAPIError.invalidServer
        }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        let prefix = base.path.hasSuffix("/") ? String(base.path.dropLast()) : base.path
        components?.path = prefix + path
        guard let url = components?.url, url.host == host else {
            throw AssistantAPIError.invalidServer
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let token = tokens?.accessToken else { throw AssistantAPIError.notSignedIn }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AssistantAPIError.unavailable }
            guard (200..<300).contains(http.statusCode) else {
                if http.statusCode == 401 && authenticated {
                    if retryAuthentication, let refreshToken = tokens?.refreshToken {
                        do {
                            let renewed: TokenResponse = try await send(
                                path: "/api/v1/auth/refresh", body: ["refresh_token": refreshToken],
                                authenticated: false, retryAuthentication: false
                            )
                            tokens = AssistantTokens(accessToken: renewed.accessToken, refreshToken: renewed.refreshToken)
                            saveTokens()
                            return try await send(path: path, body: body, authenticated: true, retryAuthentication: false)
                        } catch {
                            signOut()
                            throw AssistantAPIError.sessionExpired
                        }
                    }
                    signOut()
                    throw AssistantAPIError.sessionExpired
                }
                throw AssistantAPIError.rejected
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Response.self, from: data)
        } catch let error as AssistantAPIError {
            throw error
        } catch {
            throw AssistantAPIError.unavailable
        }
    }

    private func readTokens() -> AssistantTokens? {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: keychainService,
                                    kSecAttrAccount as String: keychainAccount,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AssistantTokens.self, from: data)
    }

    private func saveTokens() {
        guard let tokens, let data = try? JSONEncoder().encode(tokens) else { return }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: keychainService,
                                    kSecAttrAccount as String: keychainAccount]
        SecItemDelete(query as CFDictionary)
        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(insert as CFDictionary, nil)
    }
}
