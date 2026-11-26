import AppKit
import DinkyCalCore
import EventKit

enum CalendarAccess {
    case notDetermined, granted, denied
}

/// The only place that touches EventKit. Converts EKEvents into core `CalendarEvent`s.
@MainActor
final class EventStoreService {
    private let store = EKEventStore()
    var onChange: (() -> Void)?

    init() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.onChange?() }
        }
    }

    var access: CalendarAccess {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    func requestAccess() async -> CalendarAccess {
        _ = try? await store.requestFullAccessToEvents()
        return access
    }

    func calendars() -> [CalendarInfo] {
        guard access == .granted else { return [] }
        return store.calendars(for: .event).map { cal in
            let kind: CalendarKind = switch cal.type {
            case .birthday: .birthday
            case .subscription: .subscription
            default: .regular
            }
            return CalendarInfo(id: cal.calendarIdentifier, title: cal.title,
                                sourceTitle: cal.source?.title ?? "Other", kind: kind)
        }
    }

    func events(from start: Date, to end: Date, calendarIDs: Set<String>) -> [CalendarEvent] {
        guard access == .granted else { return [] }
        let calendars = store.calendars(for: .event).filter { calendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map { ev in
            let declined = ev.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined
            return CalendarEvent(
                id: "\(ev.calendarItemIdentifier)-\(ev.startDate.timeIntervalSince1970)",
                title: ev.title ?? "Untitled",
                start: ev.startDate, end: ev.endDate, isAllDay: ev.isAllDay,
                calendarID: ev.calendar.calendarIdentifier,
                isDeclined: declined, isFree: ev.availability == .free)
        }
    }

    func color(forCalendar id: String) -> NSColor? {
        store.calendar(withIdentifier: id)?.color
    }
}
