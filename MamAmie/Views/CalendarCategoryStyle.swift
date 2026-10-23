import SwiftUI

enum CalendarCategoryStyle {
    static func color(for category: EntryCategory) -> Color {
        switch category {
        case .medication: return Color("AccentColor")
        case .appointment: return .blue
        case .test: return .indigo
        case .symptom: return .orange
        case .food: return .green
        case .journal, .photo: return .purple
        case .milestone: return .yellow
        case .task: return .teal
        }
    }
}
