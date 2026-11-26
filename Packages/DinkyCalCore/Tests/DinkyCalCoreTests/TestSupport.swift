import Foundation

/// Gregorian calendar pinned to America/New_York so DST cases are deterministic.
func nyCalendar(firstWeekday: Int = 1) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/New_York")!
    cal.locale = Locale(identifier: "en_US")
    cal.firstWeekday = firstWeekday
    return cal
}

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, calendar: Calendar = nyCalendar()) -> Date {
    calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}
