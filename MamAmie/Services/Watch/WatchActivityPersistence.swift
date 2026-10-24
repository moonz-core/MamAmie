import Foundation

/// Stores received wrist activity in the phone's private Application Support directory.
/// Medical details are never written to logs or a shared cloud container.
final class WatchActivityPersistence {
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        let directory = storageURL ?? ((try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory).appendingPathComponent("MamAmie", isDirectory: true)
        fileURL = directory.appendingPathComponent("watch-activity.json")
    }

    @discardableResult
    func appendIfNeeded(_ action: WatchCompanionAction) -> Bool {
        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            var actions: [WatchCompanionAction] = []
            if fileManager.fileExists(atPath: fileURL.path) {
                actions = try JSONDecoder().decode([WatchCompanionAction].self, from: Data(contentsOf: fileURL))
            }
            guard !actions.contains(where: { $0.id == action.id }) else { return true }
            actions.append(action)
            if actions.count > 500 { actions.removeFirst(actions.count - 500) }
            let data = try JSONEncoder().encode(actions)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            return false
        }
    }
}
