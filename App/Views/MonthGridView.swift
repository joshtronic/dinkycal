import DinkyCalCore
import SwiftUI

struct MonthGridView: View {
    @EnvironmentObject var model: CalendarModel

    var body: some View {
        let grid = model.grid
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            ForEach(0..<6, id: \.self) { week in
                let days = Array(grid.days[(week * 7)..<(week * 7 + 7)])
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { column, day in
                        DayCell(day: day, column: column)
                    }
                }
                .zIndex(days.contains { $0.date == model.hoveredDay } ? 1 : 0)
            }
        }
    }
}
