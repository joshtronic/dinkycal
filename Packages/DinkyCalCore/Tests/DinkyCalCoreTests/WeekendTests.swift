import XCTest
@testable import DinkyCalCore

final class WeekendTests: XCTestCase {
    func test_usWeekendIsSaturdaySunday() {
        XCTAssertEqual(defaultWeekendWeekdays(calendar: nyCalendar()), [1, 7])
    }

    func test_regionWithFridaySaturdayWeekend() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jerusalem")!
        cal.locale = Locale(identifier: "he_IL")
        XCTAssertEqual(defaultWeekendWeekdays(calendar: cal), [6, 7])
    }

    func test_isWeekendUsesGivenWeekdays() {
        let cal = nyCalendar()
        XCTAssertTrue(isWeekend(date(2026, 11, 28), weekendWeekdays: [1, 7], calendar: cal))   // Saturday
        XCTAssertFalse(isWeekend(date(2026, 11, 27), weekendWeekdays: [1, 7], calendar: cal))  // Friday
        XCTAssertTrue(isWeekend(date(2026, 11, 27), weekendWeekdays: [6], calendar: cal))
    }
}
