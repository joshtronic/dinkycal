import DinkyCalCore
import Foundation

@MainActor
final class CalendarModel: ObservableObject {
    @Published private(set) var monthStart: Date
    @Published private(set) var today: Date
    @Published var selectedDay: Date?

    private let now: () -> Date

    var calendar: Calendar { Calendar.autoupdatingCurrent }

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
        let cal = Calendar.autoupdatingCurrent
        let today = cal.startOfDay(for: now())
        self.today = today
        self.monthStart = startOfMonth(today, calendar: cal)
        self.selectedDay = today
    }

    var grid: MonthGrid { makeMonthGrid(for: monthStart, today: today, calendar: calendar) }

    var isOnCurrentMonth: Bool { monthStart == startOfMonth(today, calendar: calendar) }

    func showPreviousMonth() { showMonth(shiftMonth(monthStart, by: -1, calendar: calendar)) }
    func showNextMonth() { showMonth(shiftMonth(monthStart, by: 1, calendar: calendar)) }

    func goToToday() {
        refreshToday()
        monthStart = startOfMonth(today, calendar: calendar)
        selectedDay = today
    }

    /// Re-reads the clock (midnight, wake, time zone change). Keeps "today"-anchored state anchored.
    func refreshToday() {
        let oldToday = today
        let newToday = calendar.startOfDay(for: now())
        guard newToday != oldToday else { return }
        let wasOnCurrentMonth = isOnCurrentMonth
        today = newToday
        if selectedDay == oldToday { selectedDay = newToday }
        if wasOnCurrentMonth { monthStart = startOfMonth(newToday, calendar: calendar) }
    }

    private func showMonth(_ month: Date) {
        monthStart = month
        if let selected = selectedDay, !grid.days.contains(where: { $0.date == selected }) {
            selectedDay = nil
        }
    }
}
