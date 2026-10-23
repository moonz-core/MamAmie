import Foundation

struct TimelineItem: Identifiable {
    enum Source: Equatable {
        case entry(UUID)
        case doseLog(UUID, UUID)
    }

    let id: String
    let source: Source
    let category: EntryCategory
    let title: String
    let summary: String
    let timeMinutes: Int?
    let status: String?
    let hasAttachment: Bool
}
