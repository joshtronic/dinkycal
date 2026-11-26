import DinkyCalCore
import SwiftUI

struct DayCell: View {
    @EnvironmentObject var model: CalendarModel
    let day: GridDay

    var body: some View {
        let number = model.calendar.component(.day, from: day.date)
        VStack(spacing: 2) {
            Text("\(number)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular).monospacedDigit())
                .foregroundStyle(day.isToday ? Color.white : Color.primary)
                .frame(width: 26, height: 26)
                .background {
                    if day.isToday { Circle().fill(Color.accentColor) }
                }
            Circle()
                .fill(HeatDot.color(level: model.busy(for: day.date).level))
                .frame(width: 6, height: 6)
        }
        .frame(height: 36)
        .opacity(day.isInMonth ? 1 : 0.35)
    }
}

enum HeatDot {
    /// Accent color at four intensity steps; level 0 draws nothing.
    static func color(level: Int) -> Color {
        let opacity: [Double] = [0, 0.3, 0.5, 0.75, 1]
        return Color(nsColor: .controlAccentColor).opacity(opacity[min(max(level, 0), 4)])
    }
}
