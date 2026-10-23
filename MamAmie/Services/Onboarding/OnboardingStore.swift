import Combine
import Foundation

@MainActor
public final class OnboardingStore: ObservableObject {
    @Published public private(set) var profile: OnboardingProfile?
    @Published public private(set) var saveErrorMessage: String?

    private let persistence: OnboardingPersistence

    public init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        persistence = OnboardingPersistence(fileManager: fileManager, storageURL: storageURL)
        load()
    }

    public var isComplete: Bool {
        profile != nil
    }

    @discardableResult
    public func save(_ profile: OnboardingProfile) -> Bool {
        do {
            try persistence.save(profile)
            self.profile = profile
            saveErrorMessage = nil
            return true
        } catch {
            saveErrorMessage = "We couldn't save your setup. Your answers are still on screen; please try again."
            return false
        }
    }

    public func reset() {
        do {
            try persistence.remove()
            profile = nil
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = "We couldn't remove your saved setup. Please try again."
        }
    }

    public func clearError() {
        saveErrorMessage = nil
    }

    private func load() {
        do {
            profile = try persistence.load()
        } catch {
            profile = nil
            saveErrorMessage = "We couldn't read your saved setup. Please complete it again."
        }
    }
}
