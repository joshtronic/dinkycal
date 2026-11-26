import Foundation

public struct DayBusy: Equatable, Sendable {
    public let eventCount: Int
    /// Busy minutes inside the day window, overlapping events merged.
    public let busyMinutes: Int
    public let hasAllDay: Bool
    /// Heatmap level, 0 (nothing) to 4 (full).
    public let level: Int

    public static let empty = DayBusy(eventCount: 0, busyMinutes: 0, hasAllDay: false, level: 0)
}

/// Events that count toward busyness on `day`: overlapping it, not declined, not marked free.
public func countedEvents(on day: Date, from events: [CalendarEvent], calendar: Calendar) -> [CalendarEvent] {
    events.filter { !$0.isDeclined && !$0.isFree && $0.overlaps(day: day, calendar: calendar) }
}

public func computeBusy(on day: Date, events: [CalendarEvent], window: DayWindow, calendar: Calendar) -> DayBusy {
    let counted = countedEvents(on: day, from: events, calendar: calendar)
    guard !counted.isEmpty else { return .empty }

    let hasAllDay = counted.contains(where: \.isAllDay)
    let (windowStart, windowEnd) = window.bounds(on: day, calendar: calendar)

    // Clip timed events to the window, then merge overlaps so concurrent events count once.
    let intervals = counted
        .filter { !$0.isAllDay }
        .map { (max($0.start, windowStart), min($0.end, windowEnd)) }
        .filter { $0.0 < $0.1 }
        .sorted { $0.0 < $1.0 }

    var seconds: TimeInterval = 0
    var current: (Date, Date)?
    for interval in intervals {
        if let c = current, interval.0 <= c.1 {
            current = (c.0, max(c.1, interval.1))
        } else {
            if let c = current { seconds += c.1.timeIntervalSince(c.0) }
            current = interval
        }
    }
    if let c = current { seconds += c.1.timeIntervalSince(c.0) }
    let busyMinutes = Int((seconds / 60).rounded())

    let level: Int
    if hasAllDay {
        level = 4
    } else {
        let ratio = Double(busyMinutes) / Double(window.minutes)
        switch ratio {
        case ..<0.25: level = 1
        case ..<0.5: level = 2
        case ..<0.75: level = 3
        default: level = 4
        }
    }

    return DayBusy(eventCount: counted.count, busyMinutes: busyMinutes, hasAllDay: hasAllDay, level: level)
}

/// "All day", "2.5h busy", "3 events", or nil when nothing is scheduled.
public func busySummary(_ busy: DayBusy) -> String? {
    if busy.eventCount == 0 { return nil }
    if busy.hasAllDay { return "All day" }
    if busy.busyMinutes > 0 {
        let halfHours = max(1, Int((Double(busy.busyMinutes) / 30).rounded()))
        let text = halfHours % 2 == 0 ? "\(halfHours / 2)" : String(format: "%.1f", Double(halfHours) / 2)
        return "\(text)h busy"
    }
    return busy.eventCount == 1 ? "1 event" : "\(busy.eventCount) events"
}
