import Foundation

public struct CalendarEvent: Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let calendarID: String
    public let isDeclined: Bool
    public let isFree: Bool

    public init(id: String, title: String, start: Date, end: Date, isAllDay: Bool,
                calendarID: String, isDeclined: Bool, isFree: Bool) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarID = calendarID
        self.isDeclined = isDeclined
        self.isFree = isFree
    }

    /// True if any part of the event falls on `day`. Zero-length events count on the day they start.
    public func overlaps(day: Date, calendar: Calendar) -> Bool {
        let dayStart = calendar.startOfDay(for: day)
        return overlaps(dayStart: dayStart, dayEnd: calendar.date(byAdding: .day, value: 1, to: dayStart)!)
    }

    /// Calendar-free overlap check against precomputed day bounds.
    func overlaps(dayStart: Date, dayEnd: Date) -> Bool {
        if start == end { return start >= dayStart && start < dayEnd }
        return start < dayEnd && end > dayStart
    }
}

/// The part of each day used to measure busyness, in minutes from midnight.
public struct DayWindow: Equatable, Sendable {
    public let startMinute: Int
    public let endMinute: Int

    public static let standard = DayWindow(startMinute: 540, endMinute: 1020)

    /// Invalid windows (end ≤ start, or outside 0...1440) fall back to 09:00–17:00.
    public init(startMinute: Int, endMinute: Int) {
        if (0..<1440).contains(startMinute), (1...1440).contains(endMinute), endMinute > startMinute {
            self.startMinute = startMinute
            self.endMinute = endMinute
        } else {
            self.startMinute = 540
            self.endMinute = 1020
        }
    }

    public var minutes: Int { endMinute - startMinute }

    /// The window's real start and end on `day` (wall-clock times, DST-aware).
    func bounds(on day: Date, calendar: Calendar) -> (Date, Date) {
        let dayStart = calendar.startOfDay(for: day)
        func at(_ minute: Int) -> Date {
            if minute == 1440 { return calendar.date(byAdding: .day, value: 1, to: dayStart)! }
            return calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: dayStart)!
        }
        return (at(startMinute), at(endMinute))
    }
}
