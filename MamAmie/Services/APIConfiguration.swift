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

    /// Optional default Gemini API Key (can be configured statically or entered in the app settings)
    public static var geminiAPIKey: String = ""

    /// Active API base URL
    #if DEBUG
    public static var currentBaseURL: URL = productionBaseURL
    #else
    public static let currentBaseURL: URL = productionBaseURL
    #endif
}
