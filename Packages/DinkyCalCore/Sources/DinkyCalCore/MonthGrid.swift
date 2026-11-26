import Foundation

public struct GridDay: Hashable, Identifiable, Sendable {
    public let date: Date
    public let isInMonth: Bool
    public let isToday: Bool
    public var id: Date { date }

    public init(date: Date, isInMonth: Bool, isToday: Bool) {
        self.date = date
        self.isInMonth = isInMonth
        self.isToday = isToday
    }
}

public struct MonthGrid: Sendable {
    /// Midnight on the first day of the month.
    public let monthStart: Date
    /// Always 42 days (6 weeks), starting on the calendar's first weekday.
    public let days: [GridDay]
    /// Very short weekday symbols rotated so index 0 is the calendar's first weekday.
    public let weekdaySymbols: [String]
}

/// Midnight on the first day of the month containing `date`.
public func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
    calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
}

public func makeMonthGrid(for month: Date, today: Date, calendar: Calendar) -> MonthGrid {
    let monthStart = startOfMonth(month, calendar: calendar)
    let monthComponent = calendar.component(.month, from: monthStart)
    let todayStart = calendar.startOfDay(for: today)

    let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
    let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart)!

    let days = (0..<42).map { offset -> GridDay in
        let day = calendar.date(byAdding: .day, value: offset, to: gridStart)!
        return GridDay(
            date: day,
            isInMonth: calendar.component(.month, from: day) == monthComponent,
            isToday: day == todayStart
        )
    }

    let symbols = calendar.veryShortWeekdaySymbols
    let first = calendar.firstWeekday - 1
    let rotated = Array(symbols[first...] + symbols[..<first])

    return MonthGrid(monthStart: monthStart, days: days, weekdaySymbols: rotated)
}

public func shiftMonth(_ monthStart: Date, by offset: Int, calendar: Calendar) -> Date {
    startOfMonth(calendar.date(byAdding: .month, value: offset, to: monthStart)!, calendar: calendar)
}

/// Week-of-year for each of the grid's 6 rows, using the calendar's own week rules
/// (US: Sunday weeks containing Jan 1; ISO: Monday weeks, 4-day minimum).
/// A row that contains Jan 1 is week 1 under US rules, so the row's last day decides.
public func weekNumbers(for grid: MonthGrid, calendar: Calendar) -> [Int] {
    (0..<6).map { row in
        calendar.component(.weekOfYear, from: grid.days[row * 7 + 6].date)
    }
}
