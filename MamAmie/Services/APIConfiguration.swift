import Foundation

/// Centralized API configuration for MamAmie iOS client communicating with the backend.
public enum APIConfiguration {
    /// Live production backend on Render
    public static let productionBaseURL = URL(string: "https://mamamie.onrender.com/api/v1")!

    /// Public interactive OpenAPI documentation
    public static let swaggerDocsURL = URL(string: "https://mamamie.onrender.com/docs")!

    /// Public health check endpoint
    public static let healthCheckURL = URL(string: "https://mamamie.onrender.com/health")!

    /// Local development fallback URL
    public static let localDevelopmentBaseURL = URL(string: "http://localhost:8000/api/v1")!

    /// Built-in default Gemini API Key (automatically active out of the box for all users)
    public static var defaultGeminiAPIKey: String {
        guard let data = Data(base64Encoded: "QVEuQWI4Uk42Sk0ybFpfSWdnam9MUlByMkpUbFFfdjlVR1Zfb1NnOWI0NnBraVcyNTd3SGc=") else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Active API base URL
    #if DEBUG
    public static var currentBaseURL: URL = productionBaseURL
    #else
    public static let currentBaseURL: URL = productionBaseURL
    #endif
}
