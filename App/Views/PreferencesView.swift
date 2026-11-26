import DinkyCalCore
import KeyboardShortcuts
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var model: CalendarModel
    @EnvironmentObject var preferences: Preferences
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var collapsed: Set<String> = []

    private func expandedBinding(_ source: String) -> Binding<Bool> {
        Binding(get: { !collapsed.contains(source) },
                set: { if $0 { collapsed.remove(source) } else { collapsed.insert(source) } })
    }

    var body: some View {
        Form {
            if model.access == .granted {
                let included = model.includedCalendarIDs
                ForEach(groupedCalendars(model.store.calendars()), id: \.source) { group in
                    Section(isExpanded: expandedBinding(group.source)) {
                        ForEach(group.calendars) { cal in
                            Toggle(isOn: Binding(
                                get: { included.contains(cal.id) },
                                set: { preferences.setCalendar(cal, included: $0) }
                            )) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(nsColor: model.store.color(forCalendar: cal.id) ?? .controlAccentColor))
                                        .frame(width: 9, height: 9)
                                    Text(cal.title)
                                }
                            }
                        }
                    } header: {
                        Text(group.source)
                    }
                }
                Section {
                    Text("Unchecked calendars don't count toward busy days. Birthdays and subscribed calendars start unchecked.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Section("Calendars") {
                    Text("Allow calendar access from the menu bar calendar to choose calendars.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Busy hours") {
                Picker("Day starts", selection: Binding(
                    get: { preferences.dayWindow.startMinute },
                    set: { preferences.dayWindow = DayWindow(startMinute: $0, endMinute: preferences.dayWindow.endMinute) }
                )) {
                    ForEach(Array(stride(from: 0, to: preferences.dayWindow.endMinute, by: 30)), id: \.self) {
                        Text(timeLabel($0)).tag($0)
                    }
                }
                Picker("Day ends", selection: Binding(
                    get: { preferences.dayWindow.endMinute },
                    set: { preferences.dayWindow = DayWindow(startMinute: preferences.dayWindow.startMinute, endMinute: $0) }
                )) {
                    ForEach(Array(stride(from: preferences.dayWindow.startMinute + 30, through: 1440, by: 30)), id: \.self) {
                        Text(timeLabel($0)).tag($0)
                    }
                }
                Text("Used to measure how busy a day is: a fully booked window gets the brightest dot. Separate from Calendar's \"Day starts at\" setting.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Display") {
                Toggle("Show week numbers", isOn: $preferences.showWeekNumbers)
                Toggle("Dim weekends", isOn: $preferences.dimWeekends)
                if preferences.dimWeekends {
                    LabeledContent("Weekend days") {
                        HStack(spacing: 4) {
                            ForEach(orderedWeekdays, id: \.self) { weekday in
                                let on = model.weekendWeekdays.contains(weekday)
                                Button(model.calendar.veryShortWeekdaySymbols[weekday - 1]) {
                                    var days = model.weekendWeekdays
                                    if on { days.remove(weekday) } else { days.insert(weekday) }
                                    preferences.weekendDays = days
                                }
                                .buttonStyle(.plain)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(on ? Color.accentColor : Color.primary.opacity(0.08)))
                                .foregroundStyle(on ? Color.white : Color.primary)
                                .accessibilityLabel(model.calendar.weekdaySymbols[weekday - 1])
                                .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                    }
                    if preferences.weekendDays != nil {
                        Button("Use my region's weekend") { preferences.weekendDays = nil }
                    }
                }
                Picker("Menu bar icon", selection: $preferences.iconStyle) {
                    Text("Today's date").tag(IconStyle.date)
                    Text("Plain icon").tag(IconStyle.glyph)
                }
            }

            Section("General") {
                KeyboardShortcuts.Recorder("Show calendar:", name: .togglePopover)
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { _ in LaunchAtLogin.toggle(); launchAtLogin = LaunchAtLogin.isEnabled }
                ))
            }
        }
        .formStyle(.grouped)
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            launchAtLogin = LaunchAtLogin.isEnabled
        }
        .frame(width: 460, height: 600)
    }

    /// Weekday numbers (1 = Sunday) starting from the user's first weekday.
    private var orderedWeekdays: [Int] {
        (0..<7).map { (model.calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    private func timeLabel(_ minute: Int) -> String {
        if minute == 1440 { return "Midnight" }
        var parts = DateComponents()
        parts.hour = minute / 60
        parts.minute = minute % 60
        let date = Calendar.current.date(from: parts) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
