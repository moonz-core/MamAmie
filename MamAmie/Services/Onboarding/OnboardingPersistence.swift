import Foundation

/// Local persistence for onboarding metadata. The file remains inside the app sandbox
/// and is intentionally separate from any account or remote service layer.
final class OnboardingPersistence {
    private let fileManager: FileManager
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager

        let baseDirectory: URL
        if let storageURL {
            baseDirectory = storageURL
        } else if let applicationSupport = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            baseDirectory = applicationSupport.appendingPathComponent("MamAmie", isDirectory: true)
        } else {
            baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("MamAmie", isDirectory: true)
        }

        fileURL = baseDirectory.appendingPathComponent("onboarding.json")
    }

    func load() throws -> OnboardingProfile? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(OnboardingProfile.self, from: data)
    }

    func save(_ profile: OnboardingProfile) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(profile)
        try data.write(to: fileURL, options: .atomic)
    }

    func remove() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}
