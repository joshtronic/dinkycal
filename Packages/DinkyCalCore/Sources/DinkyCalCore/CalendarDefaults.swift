import Foundation

public enum CalendarKind: Sendable {
    case regular, birthday, subscription
}

public struct CalendarInfo: Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let sourceTitle: String
    public let kind: CalendarKind

    public init(id: String, title: String, sourceTitle: String, kind: CalendarKind) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
        self.kind = kind
    }
}

/// Birthdays and subscribed feeds (mostly holidays) start unchecked; they'd flood the heatmap.
public func isIncludedByDefault(_ calendar: CalendarInfo) -> Bool {
    calendar.kind == .regular
}

/// `userExcluded == nil` means the user never customized, so defaults apply.
/// Calendars added later follow the default rule unless the user changed them.
public func includedCalendarIDs(all: [CalendarInfo], userExcluded: Set<String>?, userIncluded: Set<String>) -> Set<String> {
    let excluded = userExcluded ?? []
    return Set(all.filter { cal in
        userIncluded.contains(cal.id) || (isIncludedByDefault(cal) && !excluded.contains(cal.id))
    }.map(\.id))
}

/// Events to list for a day: declined omitted (free kept), all-day first by title, then by start, then title.
public func eventsForList(on day: Date, events: [CalendarEvent], calendar: Calendar) -> [CalendarEvent] {
    events
        .filter { !$0.isDeclined && $0.overlaps(day: day, calendar: calendar) }
        .sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            if !a.isAllDay, a.start != b.start { return a.start < b.start }
            return a.title.localizedStandardCompare(b.title) == .orderedAscending
        }
}
