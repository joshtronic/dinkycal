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
                HStack(spacing: 0) {
                    ForEach(grid.days[(week * 7)..<(week * 7 + 7)]) { day in
                        DayCell(day: day)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}
