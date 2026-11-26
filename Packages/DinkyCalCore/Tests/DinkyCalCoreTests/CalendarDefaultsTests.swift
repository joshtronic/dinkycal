import XCTest
@testable import DinkyCalCore

final class CalendarDefaultsTests: XCTestCase {
    let work = CalendarInfo(id: "work", title: "Work", sourceTitle: "Google", kind: .regular)
    let bdays = CalendarInfo(id: "bd", title: "Birthdays", sourceTitle: "Other", kind: .birthday)
    let holidays = CalendarInfo(id: "hol", title: "US Holidays", sourceTitle: "Subscribed", kind: .subscription)
    let personal = CalendarInfo(id: "home", title: "Home", sourceTitle: "iCloud", kind: .regular)

    func test_defaultsExcludeBirthdayAndSubscription() {
        XCTAssertTrue(isIncludedByDefault(work))
        XCTAssertFalse(isIncludedByDefault(bdays))
        XCTAssertFalse(isIncludedByDefault(holidays))
        XCTAssertEqual(includedCalendarIDs(all: [work, bdays, holidays], userExcluded: nil, userIncluded: []), ["work"])
    }
    func test_newRegularCalendarIncludedAfterCustomizing() {
        let ids = includedCalendarIDs(all: [work, bdays, holidays, personal], userExcluded: ["work"], userIncluded: [])
        XCTAssertEqual(ids, ["home"])
    }
    func test_userIncludedSubscriptionStays() {
        let ids = includedCalendarIDs(all: [work, holidays], userExcluded: [], userIncluded: ["hol"])
        XCTAssertEqual(ids, ["work", "hol"])
    }

    func test_eventsForListOrdering() {
        let cal = nyCalendar()
        func ev(_ id: String, _ title: String, _ s: Date, _ e: Date, allDay: Bool = false, declined: Bool = false, free: Bool = false) -> CalendarEvent {
            CalendarEvent(id: id, title: title, start: s, end: e, isAllDay: allDay, calendarID: "c", isDeclined: declined, isFree: free)
        }
        let events = [
            ev("t2", "Lunch", date(2026, 11, 26, 12), date(2026, 11, 26, 13)),
            ev("a2", "Zoo trip", date(2026, 11, 26), date(2026, 11, 27), allDay: true),
            ev("t1", "Standup", date(2026, 11, 26, 9), date(2026, 11, 26, 9, 15)),
            ev("a1", "Holiday", date(2026, 11, 26), date(2026, 11, 27), allDay: true),
            ev("t3", "Another lunch", date(2026, 11, 26, 12), date(2026, 11, 26, 12, 30), free: true),
            ev("d", "Declined", date(2026, 11, 26, 14), date(2026, 11, 26, 15), declined: true),
            ev("x", "Tomorrow", date(2026, 11, 27, 9), date(2026, 11, 27, 10)),
        ]
        XCTAssertEqual(eventsForList(on: date(2026, 11, 26), events: events, calendar: cal).map(\.id),
                       ["a1", "a2", "t1", "t3", "t2"])
    }
}
