#if DEBUG
import DinkyCalCore
import Foundation

/// Synthetic events for screenshots and the website. Never shipped (DEBUG only).
enum DemoEvents {
    private struct Item { let day: Int; let hour: Double; let hours: Double; let title: String; var allDay = false }

    private static let items: [Item] = [
        Item(day: 2, hour: 9.5, hours: 0.5, title: "Standup"),
        Item(day: 3, hour: 10, hours: 1, title: "1:1 with Sam"),
        Item(day: 3, hour: 13, hours: 2, title: "Design review"),
        Item(day: 5, hour: 15, hours: 1, title: "Dentist"),
        Item(day: 9, hour: 9.5, hours: 0.5, title: "Standup"),
        Item(day: 10, hour: 9, hours: 4, title: "Planning offsite"),
        Item(day: 10, hour: 14, hours: 1.5, title: "Roadmap sync"),
        Item(day: 12, hour: 12, hours: 1, title: "Lunch with Ana"),
        Item(day: 16, hour: 9.5, hours: 0.5, title: "Standup"),
        Item(day: 17, hour: 10, hours: 1, title: "1:1 with Sam"),
        Item(day: 18, hour: 9, hours: 8, title: "Release day", allDay: true),
        Item(day: 19, hour: 11, hours: 2.5, title: "Pairing"),
        Item(day: 20, hour: 16, hours: 1, title: "Haircut"),
        Item(day: 23, hour: 9.5, hours: 0.5, title: "Standup"),
        Item(day: 24, hour: 10, hours: 1, title: "Interview loop"),
        Item(day: 24, hour: 13, hours: 3, title: "Workshop"),
        Item(day: 26, hour: 9.5, hours: 0.5, title: "Standup"),
        Item(day: 26, hour: 11, hours: 1, title: "Design review"),
        Item(day: 26, hour: 14, hours: 2, title: "Pairing with Lee"),
        Item(day: 27, hour: 18, hours: 2, title: "Dinner with friends"),
        Item(day: 30, hour: 9, hours: 6.5, title: "Conference talks"),
    ]

    static func month(containing day: Date, calendar: Calendar) -> [CalendarEvent] {
        let monthStart = startOfMonth(day, calendar: calendar)
        return items.enumerated().compactMap { index, item in
            guard let dayStart = calendar.date(byAdding: .day, value: item.day - 1, to: monthStart) else { return nil }
            let start = item.allDay ? dayStart : dayStart.addingTimeInterval(item.hour * 3600)
            let end = item.allDay ? calendar.date(byAdding: .day, value: 1, to: dayStart)! : start.addingTimeInterval(item.hours * 3600)
            return CalendarEvent(id: "demo-\(index)", title: item.title, start: start, end: end, isAllDay: item.allDay,
                                 calendarID: "demo", isDeclined: false, isFree: false)
        }
    }
}
#endif
