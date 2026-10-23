import SwiftUI

struct CalendarLegendView: View {
    private let categories: [EntryCategory] = [.medication, .appointment, .symptom, .journal]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(categories) { category in
                HStack(spacing: 5) {
                    Circle()
                        .fill(CalendarCategoryStyle.color(for: category))
                        .frame(width: 7, height: 7)
                    Text(category.shortName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calendar indicators show medication, appointments, wellbeing, food, and journal entries")
    }
}
