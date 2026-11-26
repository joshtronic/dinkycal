import DinkyCalCore
import Foundation

/// User settings, persisted in UserDefaults.
@MainActor
final class Preferences: ObservableObject {
    private enum Key {
        static let dayWindowStart = "dayWindowStart"
        static let dayWindowEnd = "dayWindowEnd"
        static let excluded = "excludedCalendars"
        static let included = "includedCalendars"
        static let iconStyle = "iconStyle"
        static let showWeekNumbers = "showWeekNumbers"
        static let weekendDays = "weekendDays"
        static let dimWeekends = "dimWeekends"
    }

    private let defaults: UserDefaults

    @Published var dayWindow: DayWindow {
        didSet {
            defaults.set(dayWindow.startMinute, forKey: Key.dayWindowStart)
            defaults.set(dayWindow.endMinute, forKey: Key.dayWindowEnd)
        }
    }
    /// nil until the user customizes the calendar list.
    @Published var userExcludedCalendarIDs: Set<String>? {
        didSet { defaults.set(userExcludedCalendarIDs.map(Array.init), forKey: Key.excluded) }
    }
    @Published var userIncludedCalendarIDs: Set<String> {
        didSet { defaults.set(Array(userIncludedCalendarIDs), forKey: Key.included) }
    }
    @Published var iconStyle: IconStyle {
        didSet { defaults.set(iconStyle.rawValue, forKey: Key.iconStyle) }
    }

    @Published var showWeekNumbers: Bool {
        didSet { defaults.set(showWeekNumbers, forKey: Key.showWeekNumbers) }
    }

    /// nil means "use my region's weekend".
    @Published var weekendDays: Set<Int>? {
        didSet { defaults.set(weekendDays.map { Array($0) }, forKey: Key.weekendDays) }
    }
    @Published var dimWeekends: Bool {
        didSet { defaults.set(dimWeekends, forKey: Key.dimWeekends) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.dayWindowStart) != nil {
            dayWindow = DayWindow(startMinute: defaults.integer(forKey: Key.dayWindowStart),
                                  endMinute: defaults.integer(forKey: Key.dayWindowEnd))
        } else {
            dayWindow = .standard
        }
        userExcludedCalendarIDs = (defaults.array(forKey: Key.excluded) as? [String]).map(Set.init)
        userIncludedCalendarIDs = Set(defaults.array(forKey: Key.included) as? [String] ?? [])
        showWeekNumbers = defaults.bool(forKey: Key.showWeekNumbers)
        weekendDays = (defaults.array(forKey: Key.weekendDays) as? [Int]).map(Set.init)
        dimWeekends = defaults.object(forKey: Key.dimWeekends) as? Bool ?? true
        iconStyle = IconStyle(rawValue: defaults.string(forKey: Key.iconStyle) ?? "") ?? .date
    }

    func setCalendar(_ calendar: CalendarInfo, included: Bool) {
        var excluded = userExcludedCalendarIDs ?? []
        var includedIDs = userIncludedCalendarIDs
        if included {
            excluded.remove(calendar.id)
            if !isIncludedByDefault(calendar) { includedIDs.insert(calendar.id) }
        } else {
            includedIDs.remove(calendar.id)
            if isIncludedByDefault(calendar) { excluded.insert(calendar.id) }
        }
        userExcludedCalendarIDs = excluded
        userIncludedCalendarIDs = includedIDs
    }
}
