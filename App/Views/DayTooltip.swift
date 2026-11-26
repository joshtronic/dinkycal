import DinkyCalCore
import SwiftUI

/// Instant hover label: "In 7 days · 2h busy". The system `.help` tooltip lags about a second.
struct DayTooltip: View {
    @EnvironmentObject var model: CalendarModel
    let day: Date

    var body: some View {
        let distance = distanceLabel(dayDistance(from: model.today, to: day, calendar: model.calendar))
        let text = [distance, busySummary(model.busy(for: day))].compactMap { $0 }.joined(separator: " · ")
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.primary.opacity(0.85)))
            .fixedSize()
    }
}
