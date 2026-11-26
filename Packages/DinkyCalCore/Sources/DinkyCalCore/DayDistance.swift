import Foundation

/// Whole calendar days from today to `day`. Today itself is not counted,
/// so the same weekday next week is 7. Negative for past days.
public func dayDistance(from today: Date, to day: Date, calendar: Calendar) -> Int {
    calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: day)).day ?? 0
}

public func distanceLabel(_ days: Int) -> String {
    switch days {
    case 0: "Today"
    case 1: "Tomorrow"
    case -1: "Yesterday"
    case let n where n > 0: "In \(n) days"
    default: "\(-days) days ago"
    }
}
