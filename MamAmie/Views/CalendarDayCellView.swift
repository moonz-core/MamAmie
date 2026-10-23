import SwiftUI

struct CalendarDayCellView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let indicators: [EntryCategory]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isSelected || isToday ? .bold : .regular))
                    .frame(width: 34, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(Color("AccentColor"))
                        } else if isToday {
                            Circle().stroke(Color("AccentColor"), lineWidth: 1.5)
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.primary)

                HStack(spacing: 2) {
                    ForEach(Array(indicators.prefix(3)), id: \.self) { category in
                        Circle()
                            .fill(CalendarCategoryStyle.color(for: category))
                            .frame(width: 4.5, height: 4.5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(indicators.isEmpty ? "No entries" : "Has \(indicators.count) categories of entries")
    }
}
