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
                .fill(Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 36)
        .opacity(day.isInMonth ? 1 : 0.35)
    }
}
