import SwiftUI

struct MonthCalendarView: View {
    @ObservedObject var store: JournalStore
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            monthNavigation
            calendarGrid
            CalendarLegendView()
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Previous month")

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Color("AccentColor"))
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    CalendarDayCellView(
                        date: day,
                        isSelected: LocalDay.key(for: day) == LocalDay.key(for: selectedDate),
                        isToday: LocalDay.key(for: day) == LocalDay.key(for: Date()),
                        indicators: store.categoryIndicators(for: LocalDay.key(for: day))
                    ) {
                        selectedDate = day
                    }
                } else {
                    Color.clear
                        .frame(height: 48)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let calendar = LocalDay.calendar
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = max(1, min(calendar.firstWeekday, symbols.count)) - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var calendarDays: [Date?] {
        let calendar = LocalDay.calendar
        let firstDay = LocalDay.startOfMonth(for: displayedMonth)
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 0
        let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let dates = (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: $0, to: firstDay)
        }
        return Array<Date?>(repeating: nil, count: weekdayOffset) + dates.map { Optional($0) }
    }

    private func moveMonth(by value: Int) {
        let calendar = LocalDay.calendar
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        displayedMonth = LocalDay.startOfMonth(for: newMonth)
        let selectedMonth = String(LocalDay.key(for: selectedDate).prefix(7))
        let newMonthKey = String(LocalDay.key(for: displayedMonth).prefix(7))
        if selectedMonth != newMonthKey {
            selectedDate = displayedMonth
        }
    }
}
