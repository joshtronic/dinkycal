import XCTest
@testable import DinkyCalCore

final class MonthGridTests: XCTestCase {
    func test_novemberStartsSunday_firstWeekdaySunday() {
        let cal = nyCalendar(firstWeekday: 1)
        let grid = makeMonthGrid(for: date(2026, 11, 15), today: date(2026, 11, 26), calendar: cal)
        XCTAssertEqual(grid.monthStart, date(2026, 11, 1))
        XCTAssertEqual(grid.days.count, 42)
        XCTAssertEqual(grid.days[0].date, date(2026, 11, 1))
        XCTAssertTrue(grid.days[0].isInMonth)
        XCTAssertEqual(grid.days[29].date, date(2026, 11, 30))
        XCTAssertEqual(grid.days[30].date, date(2026, 12, 1))
        XCTAssertFalse(grid.days[30].isInMonth)
        XCTAssertEqual(grid.weekdaySymbols.first, cal.veryShortWeekdaySymbols[0])
    }

    func test_november_firstWeekdayMonday() {
        let cal = nyCalendar(firstWeekday: 2)
        let grid = makeMonthGrid(for: date(2026, 11, 1), today: date(2026, 11, 26), calendar: cal)
        XCTAssertEqual(grid.days[0].date, date(2026, 10, 26))
        XCTAssertFalse(grid.days[0].isInMonth)
        XCTAssertEqual(grid.days[6].date, date(2026, 11, 1))
        XCTAssertEqual(grid.weekdaySymbols.first, cal.veryShortWeekdaySymbols[1])
        XCTAssertEqual(grid.weekdaySymbols.count, 7)
    }

    func test_todayFlag() {
        let grid = makeMonthGrid(for: date(2026, 11, 1), today: date(2026, 11, 26, 15), calendar: nyCalendar())
        let todays = grid.days.filter(\.isToday)
        XCTAssertEqual(todays.map(\.date), [date(2026, 11, 26)])
    }

    func test_dstMonthDatesAreMidnights() {
        let cal = nyCalendar()
        let grid = makeMonthGrid(for: date(2026, 3, 1), today: date(2026, 11, 26), calendar: cal)
        for (i, day) in grid.days.enumerated() {
            XCTAssertEqual(day.date, cal.startOfDay(for: day.date))
            if i > 0 {
                XCTAssertEqual(cal.dateComponents([.day], from: grid.days[i - 1].date, to: day.date).day, 1)
            }
        }
    }

    func test_shiftMonth() {
        let cal = nyCalendar()
        XCTAssertEqual(shiftMonth(date(2026, 12, 1), by: 1, calendar: cal), date(2027, 1, 1))
        XCTAssertEqual(shiftMonth(date(2026, 1, 1), by: -1, calendar: cal), date(2025, 12, 1))
    }
}
