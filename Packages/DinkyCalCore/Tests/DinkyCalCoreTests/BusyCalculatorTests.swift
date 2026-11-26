import XCTest
@testable import DinkyCalCore

final class BusyCalculatorTests: XCTestCase {
    let cal = nyCalendar()
    let day = date(2026, 11, 26)
    let window = DayWindow.standard

    func ev(_ start: Date, _ end: Date, allDay: Bool = false, declined: Bool = false, free: Bool = false) -> CalendarEvent {
        CalendarEvent(id: UUID().uuidString, title: "e", start: start, end: end, isAllDay: allDay,
                      calendarID: "c", isDeclined: declined, isFree: free)
    }
    func at(_ h: Int, _ m: Int = 0) -> Date { date(2026, 11, 26, h, m) }
    func busy(_ events: [CalendarEvent], on d: Date? = nil, window w: DayWindow? = nil) -> DayBusy {
        computeBusy(on: d ?? day, events: events, window: w ?? window, calendar: cal)
    }

    func test_noEvents() {
        let b = busy([])
        XCTAssertEqual(b.level, 0)
        XCTAssertEqual(b.eventCount, 0)
        XCTAssertNil(busySummary(b))
    }
    func test_oneHour() {
        let b = busy([ev(at(10), at(11))])
        XCTAssertEqual(b.busyMinutes, 60)
        XCTAssertEqual(b.level, 1)
        XCTAssertEqual(busySummary(b), "1h busy")
    }
    func test_overlapMergedOnce() {
        let b = busy([ev(at(10), at(12)), ev(at(11), at(13))])
        XCTAssertEqual(b.busyMinutes, 180)
        XCTAssertEqual(b.level, 2)
        XCTAssertEqual(busySummary(b), "3h busy")
    }
    func test_thresholds() {
        XCTAssertEqual(busy([ev(at(9), at(11))]).level, 2)
        XCTAssertEqual(busy([ev(at(9), at(13))]).level, 3)
        XCTAssertEqual(busy([ev(at(9), at(14, 30))]).level, 3)
        XCTAssertEqual(busy([ev(at(9), at(15))]).level, 4)
        XCTAssertEqual(busySummary(busy([ev(at(9), at(11, 30))])), "2.5h busy")
        XCTAssertEqual(busySummary(busy([ev(at(9), at(10, 40))])), "1.5h busy")
    }
    func test_tinyBusyRoundsUpToHalfHour() {
        XCTAssertEqual(busySummary(busy([ev(at(9), at(9, 10))])), "0.5h busy")
    }
    func test_clippedToWindow() {
        XCTAssertEqual(busy([ev(at(7), at(10))]).busyMinutes, 60)
    }
    func test_outsideWindowOnly() {
        let one = busy([ev(at(19), at(21))])
        XCTAssertEqual(one.busyMinutes, 0)
        XCTAssertEqual(one.level, 1)
        XCTAssertEqual(one.eventCount, 1)
        XCTAssertEqual(busySummary(one), "1 event")
        XCTAssertEqual(busySummary(busy([ev(at(19), at(20)), ev(at(21), at(22))])), "2 events")
    }
    func test_zeroLengthEventCounts() {
        let b = busy([ev(at(10), at(10))])
        XCTAssertEqual(b.eventCount, 1)
        XCTAssertEqual(b.level, 1)
    }
    func test_allDay() {
        let b = busy([ev(date(2026, 11, 26), date(2026, 11, 27), allDay: true)])
        XCTAssertTrue(b.hasAllDay)
        XCTAssertEqual(b.level, 4)
        XCTAssertEqual(busySummary(b), "All day")
    }
    func test_multiDayAllDay() {
        let e = ev(date(2026, 11, 25), date(2026, 11, 28), allDay: true)
        for d in [25, 26, 27] { XCTAssertEqual(busy([e], on: date(2026, 11, d)).level, 4, "day \(d)") }
        XCTAssertEqual(busy([e], on: date(2026, 11, 28)).level, 0)
    }
    func test_crossesMidnight() {
        let e = ev(date(2026, 11, 26, 16), date(2026, 11, 27, 10))
        XCTAssertEqual(busy([e], on: date(2026, 11, 26)).busyMinutes, 60)
        XCTAssertEqual(busy([e], on: date(2026, 11, 27)).busyMinutes, 60)
    }
    func test_declinedAndFreeIgnored() {
        let b = busy([ev(at(10), at(11), declined: true), ev(at(12), at(13), free: true)])
        XCTAssertEqual(b, .empty)
    }
    func test_invalidWindowFallsBack() {
        XCTAssertEqual(DayWindow(startMinute: 600, endMinute: 600), .standard)
        XCTAssertEqual(DayWindow(startMinute: -5, endMinute: 600), .standard)
        XCTAssertEqual(DayWindow(startMinute: 0, endMinute: 1441), .standard)
        XCTAssertEqual(DayWindow(startMinute: 480, endMinute: 1080).minutes, 600)
    }
    func test_dstDayClipping() {
        let full = DayWindow(startMinute: 0, endMinute: 1440)
        let b = busy([ev(date(2026, 11, 1, 0), date(2026, 11, 1, 3))], on: date(2026, 11, 1), window: full)
        XCTAssertEqual(b.busyMinutes, 240)
        XCTAssertEqual(b.level, 1)
    }
}

final class BusyMapTests: XCTestCase {
    func test_busyMapMatchesPerDayComputation() {
        let cal = nyCalendar()
        let grid = makeMonthGrid(for: date(2026, 11, 1), today: date(2026, 11, 26), calendar: cal)
        func ev(_ s: Date, _ e: Date, allDay: Bool = false, free: Bool = false) -> CalendarEvent {
            CalendarEvent(id: UUID().uuidString, title: "e", start: s, end: e, isAllDay: allDay, calendarID: "c", isDeclined: false, isFree: free)
        }
        let events = [
            ev(date(2026, 11, 3, 10), date(2026, 11, 3, 12)),
            ev(date(2026, 11, 3, 11), date(2026, 11, 3, 14)),
            ev(date(2026, 11, 24, 15), date(2026, 11, 29, 16)),
            ev(date(2026, 11, 18), date(2026, 11, 20), allDay: true),
            ev(date(2026, 11, 1, 0), date(2026, 11, 1, 3)),
            ev(date(2026, 11, 7, 10), date(2026, 11, 7, 10)),
            ev(date(2026, 11, 9, 9), date(2026, 11, 9, 17), free: true),
        ]
        let window = DayWindow.standard
        let map = busyByDay(grid.days.map(\.date), events: events, window: window, calendar: cal)
        XCTAssertEqual(map.count, 42)
        for day in grid.days {
            XCTAssertEqual(map[day.date], computeBusy(on: day.date, events: events, window: window, calendar: cal), "\(day.date)")
        }
    }
}
