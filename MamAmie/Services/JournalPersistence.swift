import Foundation

/// Encapsulates local journal storage so the observable store stays focused on domain operations.
final class JournalPersistence {
    private let fileManager: FileManager
    private let journalURL: URL
    private let attachmentDirectory: URL

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

        journalURL = baseDirectory.appendingPathComponent("journal.json")
        attachmentDirectory = baseDirectory.appendingPathComponent("Attachments", isDirectory: true)
    }

    func load() throws -> JournalStoreData {
        try ensureBaseDirectory()
        guard fileManager.fileExists(atPath: journalURL.path) else {
            return JournalStoreData()
        }

        let data = try Data(contentsOf: journalURL)
        return try JSONDecoder().decode(JournalStoreData.self, from: data)
    }

    func save(_ storeData: JournalStoreData) throws {
        try ensureBaseDirectory()
        let data = try JSONEncoder().encode(storeData)
        try data.write(to: journalURL, options: .atomic)
    }

    func saveAttachment(_ data: Data) throws -> AttachmentReference {
        try fileManager.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true)

        let id = UUID()
        let reference = AttachmentReference(
            id: id,
            fileName: "\(id.uuidString).image",
            createdAt: Date(),
            mediaType: "image"
        )
        try data.write(to: attachmentURL(for: reference), options: .atomic)
        return reference
    }

    func deleteAttachment(_ reference: AttachmentReference) {
        try? fileManager.removeItem(at: attachmentURL(for: reference))
    }

    func removeAll() throws {
        if fileManager.fileExists(atPath: journalURL.path) {
            try fileManager.removeItem(at: journalURL)
        }
        if fileManager.fileExists(atPath: attachmentDirectory.path) {
            try? fileManager.removeItem(at: attachmentDirectory)
        }
    }

    func data(for reference: AttachmentReference) -> Data? {
        try? Data(contentsOf: attachmentURL(for: reference))
    }

    func deleteData() {
        try? fileManager.removeItem(at: journalURL)
        try? fileManager.removeItem(at: attachmentDirectory)
    }

    private func ensureBaseDirectory() throws {
        try fileManager.createDirectory(
            at: journalURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func attachmentURL(for reference: AttachmentReference) -> URL {
        attachmentDirectory.appendingPathComponent(reference.fileName, isDirectory: false)
    }
}
