import AppKit
import DinkyCalCore
import SwiftUI

/// The selected day's summary and events, plus the popover footer.
struct DayDetailView: View {
    @EnvironmentObject var model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.access != .granted {
                AccessPromptView()
            } else if let day = model.selectedDay {
                Text(header(for: day))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                let events = model.events(for: day)
                if events.isEmpty {
                    Text("Nothing scheduled.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(events) { EventRow(event: $0, day: day) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: min(CGFloat(events.count) * 24, 180))
                }
            } else {
                Text("Select a day")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Open Calendar") {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
                        NSWorkspace.shared.openApplication(at: url, configuration: .init())
                    }
                    model.closePopover()
                }
                .buttonStyle(PillButtonStyle())
                Spacer()
                Button { model.showMenu() } label: { Image(systemName: "gearshape") }
                    .buttonStyle(RoundIconButtonStyle())
                    .help("Settings")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(for day: Date) -> String {
        let date = day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let distance = distanceLabel(dayDistance(from: model.today, to: day, calendar: model.calendar))
        return [date, distance, busySummary(model.busy(for: day))].compactMap { $0 }.joined(separator: " · ")
    }
}

private struct EventRow: View {
    @EnvironmentObject var model: CalendarModel
    let event: CalendarEvent
    let day: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(Color(nsColor: model.store.color(forCalendar: event.calendarID) ?? .controlAccentColor))
                .frame(width: 7, height: 7)
            Text(timeText)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)
            Text(event.title)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .opacity(event.isFree ? 0.6 : 1)
        }
        .help(event.title)
    }

    private var timeText: String {
        func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
        switch eventSpan(event, on: day, calendar: model.calendar) {
        case .allDay: return "All day"
        case let .range(start, end): return "\(time(start))–\(time(end))"
        case let .from(start): return "From \(time(start))"
        case let .until(end): return "Until \(time(end))"
        }
    }
}
