import XCTest
@testable import DinkyCalCore

final class DayDistanceTests: XCTestCase {
    let cal = nyCalendar()

    func test_nextTuesdayIsSeven() {
        XCTAssertEqual(dayDistance(from: date(2026, 11, 24, 23, 30), to: date(2026, 12, 1, 0, 10), calendar: cal), 7)
    }
    func test_today() {
        XCTAssertEqual(dayDistance(from: date(2026, 11, 26, 1), to: date(2026, 11, 26, 23, 59), calendar: cal), 0)
    }
    func test_pastDays() {
        XCTAssertEqual(dayDistance(from: date(2026, 11, 26), to: date(2026, 11, 23), calendar: cal), -3)
    }
    func test_acrossSpringForward() {
        XCTAssertEqual(dayDistance(from: date(2026, 3, 7, 12), to: date(2026, 3, 9, 12), calendar: cal), 2)
    }
    func test_acrossFallBack() {
        XCTAssertEqual(dayDistance(from: date(2026, 10, 31, 23), to: date(2026, 11, 2), calendar: cal), 2)
    }
    func test_acrossYear() {
        XCTAssertEqual(dayDistance(from: date(2026, 12, 31, 22), to: date(2027, 1, 1, 1), calendar: cal), 1)
    }
    func test_labels() {
        XCTAssertEqual(distanceLabel(0), "Today")
        XCTAssertEqual(distanceLabel(1), "Tomorrow")
        XCTAssertEqual(distanceLabel(-1), "Yesterday")
        XCTAssertEqual(distanceLabel(7), "In 7 days")
        XCTAssertEqual(distanceLabel(-3), "3 days ago")
    }
}
