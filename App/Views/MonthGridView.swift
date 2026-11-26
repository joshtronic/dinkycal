import DinkyCalCore
import SwiftUI

struct MonthGridView: View {
    @EnvironmentObject var model: CalendarModel
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        let grid = model.grid
        let weeks = preferences.showWeekNumbers ? weekNumbers(for: grid, calendar: model.calendar) : nil
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                if weeks != nil { WeekNumberLabel(text: "Wk").foregroundStyle(.tertiary) }
            }
            .padding(.bottom, 4)
            ForEach(0..<6, id: \.self) { week in
                let days = Array(grid.days[(week * 7)..<(week * 7 + 7)])
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { column, day in
                        DayCell(day: day, column: column)
                    }
                    if let weeks { WeekNumberLabel(text: "\(weeks[week])").foregroundStyle(.secondary) }
                }
                .zIndex(days.contains { $0.date == model.hoveredDay } ? 1 : 0)
            }
        }
    }
}

private struct WeekNumberLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .frame(width: 24, alignment: .trailing)
    }
}
