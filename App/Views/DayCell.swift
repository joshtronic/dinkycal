import DinkyCalCore
import SwiftUI

struct DayCell: View {
    @EnvironmentObject var model: CalendarModel
    let day: GridDay
    /// 0...6, used to keep the tooltip inside the popover at the edges.
    let column: Int

    var body: some View {
        let number = model.calendar.component(.day, from: day.date)
        let isSelected = model.selectedDay == day.date
        let isHovered = model.hoveredDay == day.date
        VStack(spacing: 2) {
            Text("\(number)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular).monospacedDigit())
                .foregroundStyle(day.isToday ? Color.white : Color.primary)
                .frame(width: 26, height: 26)
                .background {
                    if day.isToday {
                        Circle().fill(Color.accentColor)
                    } else if isHovered {
                        Circle().fill(Color.primary.opacity(0.1))
                    }
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }
            Circle()
                .fill(HeatDot.color(level: model.busy(for: day.date).level))
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .opacity(day.isInMonth ? 1 : 0.35)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside { model.hoveredDay = day.date } else if isHovered { model.hoveredDay = nil }
        }
        .onTapGesture { model.select(day.date) }
        .overlay(alignment: tooltipAlignment) {
            if isHovered { DayTooltip(day: day.date).offset(y: -30).allowsHitTesting(false) }
        }
        .zIndex(isHovered ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { model.select(day.date) }
    }

    private var tooltipAlignment: Alignment {
        switch column {
        case 0: .topLeading
        case 6: .topTrailing
        default: .top
        }
    }

    private var accessibilityText: String {
        let dateText = day.date.formatted(date: .complete, time: .omitted)
        let distance = distanceLabel(dayDistance(from: model.today, to: day.date, calendar: model.calendar))
        let busy = busySummary(model.busy(for: day.date)) ?? "Nothing scheduled"
        return "\(dateText), \(distance), \(busy)"
    }
}

enum HeatDot {
    /// Accent color at four intensity steps; level 0 draws nothing.
    static func color(level: Int) -> Color {
        let opacity: [Double] = [0, 0.45, 0.62, 0.8, 1]
        return Color(nsColor: .controlAccentColor).opacity(opacity[min(max(level, 0), 4)])
    }
}
