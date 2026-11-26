import XCTest
@testable import DinkyCalCore

final class EventSpanTests: XCTestCase {
    let cal = nyCalendar()
    func ev(_ s: Date, _ e: Date, allDay: Bool = false) -> CalendarEvent {
        CalendarEvent(id: "x", title: "t", start: s, end: e, isAllDay: allDay, calendarID: "c", isDeclined: false, isFree: false)
    }

    func test_sameDayIsRange() {
        XCTAssertEqual(eventSpan(ev(date(2026, 11, 26, 9), date(2026, 11, 26, 10)), on: date(2026, 11, 26), calendar: cal),
                       .range(date(2026, 11, 26, 9), date(2026, 11, 26, 10)))
    }
    func test_allDayFlag() {
        XCTAssertEqual(eventSpan(ev(date(2026, 11, 26), date(2026, 11, 27), allDay: true), on: date(2026, 11, 26), calendar: cal), .allDay)
    }
    func test_multiDayTimed() {
        let e = ev(date(2026, 11, 24, 15), date(2026, 11, 29, 16))
        XCTAssertEqual(eventSpan(e, on: date(2026, 11, 24), calendar: cal), .from(date(2026, 11, 24, 15)))
        XCTAssertEqual(eventSpan(e, on: date(2026, 11, 26), calendar: cal), .allDay)
        XCTAssertEqual(eventSpan(e, on: date(2026, 11, 29), calendar: cal), .until(date(2026, 11, 29, 16)))
    }
    func test_endsExactlyAtMidnightIsRangeNotFrom() {
        let e = ev(date(2026, 11, 26, 22), date(2026, 11, 27))
        XCTAssertEqual(eventSpan(e, on: date(2026, 11, 26), calendar: cal), .range(date(2026, 11, 26, 22), date(2026, 11, 27)))
    }
}
