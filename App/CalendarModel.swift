import Combine
import DinkyCalCore
import Foundation

@MainActor
final class CalendarModel: ObservableObject {
    @Published private(set) var monthStart: Date { didSet { if monthStart != oldValue { loadEvents() } } }
    @Published private(set) var today: Date
    @Published var selectedDay: Date?
    @Published var hoveredDay: Date?
    /// Hooks into the status item (set by StatusItemController).
    var showMenu: () -> Void = {}
    var closePopover: () -> Void = {}
    @Published private(set) var access: CalendarAccess
    /// Events covering the visible 42-day grid.
    @Published private(set) var events: [CalendarEvent] = [] { didSet { rebuildBusy() } }
    /// Busy summary per grid day, rebuilt only when events or the day window change,
    /// so hovering (which re-renders every cell) stays cheap.
    private var busyMap: [Date: DayBusy] = [:]

    let store: EventStoreService
    let preferences: Preferences
    private let now: () -> Date
    private var cache: [Date: [CalendarEvent]] = [:]
    private var cancellables = Set<AnyCancellable>()

    var calendar: Calendar { Calendar.autoupdatingCurrent }

    init(store: EventStoreService, preferences: Preferences, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.preferences = preferences
        self.now = now
        let cal = Calendar.autoupdatingCurrent
        let today = cal.startOfDay(for: now())
        self.today = today
        self.monthStart = startOfMonth(today, calendar: cal)
        self.selectedDay = today
        self.access = store.access

        store.onChange = { [weak self] in self?.reloadEvents() }
        preferences.objectWillChange
            .sink { [weak self] _ in DispatchQueue.main.async { self?.reloadEvents() } }
            .store(in: &cancellables)
        loadEvents()
    }

    // MARK: Events

    func busy(for day: Date) -> DayBusy {
        busyMap[calendar.startOfDay(for: day)]
            ?? computeBusy(on: day, events: events, window: preferences.dayWindow, calendar: calendar)
    }

    private func rebuildBusy() {
        busyMap = busyByDay(grid.days.map(\.date), events: events, window: preferences.dayWindow, calendar: calendar)
    }

    func events(for day: Date) -> [CalendarEvent] {
        eventsForList(on: day, events: events, calendar: calendar)
    }

    var weekendWeekdays: Set<Int> {
        preferences.weekendDays ?? defaultWeekendWeekdays(calendar: calendar)
    }

    /// Weekend days are drawn dimmer, unless the user turned that off.
    func isDimmedWeekend(_ day: Date) -> Bool {
        preferences.dimWeekends && isWeekend(day, weekendWeekdays: weekendWeekdays, calendar: calendar)
    }

    var includedCalendarIDs: Set<String> {
        DinkyCalCore.includedCalendarIDs(all: store.calendars(),
                                         userExcluded: preferences.userExcludedCalendarIDs,
                                         userIncluded: preferences.userIncludedCalendarIDs)
    }

    /// Drops cached months and refetches (calendar data, access, or preferences changed).
    func reloadEvents() {
        access = store.access
        cache.removeAll()
        loadEvents()
    }

    func requestAccess() async {
        access = await store.requestAccess()
        reloadEvents()
    }

    #if DEBUG
    /// Debug-only: replaces calendar data with a synthetic month for screenshots.
    func loadDemo() {
        demoMode = true
        access = .granted
        events = DemoEvents.month(containing: today, calendar: calendar)
    }
    private var demoMode = false
    #endif

    private func loadEvents() {
        #if DEBUG
        if demoMode { return }
        #endif
        guard access == .granted else { events = []; return }
        if let cached = cache[monthStart] { events = cached; return }
        let days = grid.days
        guard let first = days.first?.date, let last = days.last?.date,
              let end = calendar.date(byAdding: .day, value: 1, to: last) else { return }
        let fetched = store.events(from: first, to: end, calendarIDs: includedCalendarIDs)
        cache[monthStart] = fetched
        events = fetched
    }

    var grid: MonthGrid { makeMonthGrid(for: monthStart, today: today, calendar: calendar) }

    var isOnCurrentMonth: Bool { monthStart == startOfMonth(today, calendar: calendar) }

    func showPreviousMonth() { showMonth(shiftMonth(monthStart, by: -1, calendar: calendar)) }
    func showNextMonth() { showMonth(shiftMonth(monthStart, by: 1, calendar: calendar)) }

    func goToToday() {
        if store.access != access { reloadEvents() }
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

    func select(_ day: Date) {
        selectedDay = calendar.startOfDay(for: day)
    }

    /// Moves the selection by whole days, switching months when it leaves the current one.
    func moveSelection(byDays days: Int) {
        let base = selectedDay ?? (isOnCurrentMonth ? today : monthStart)
        guard let target = calendar.date(byAdding: .day, value: days, to: base) else { return }
        let targetMonth = startOfMonth(target, calendar: calendar)
        if targetMonth != monthStart { showMonth(targetMonth) }
        selectedDay = target
    }

    private func showMonth(_ month: Date) {
        monthStart = month
        hoveredDay = nil
        if let selected = selectedDay, !grid.days.contains(where: { $0.date == selected }) {
            selectedDay = nil
        }
    }
}
