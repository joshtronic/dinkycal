import AppKit
import SwiftUI

/// Shown under the grid until calendar access is granted. The calendar works either way.
struct AccessPromptView: View {
    @EnvironmentObject var model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch model.access {
            case .notDetermined:
                Text("See which days are busy by letting Dinky Cal read your calendars. Nothing leaves your Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Show My Events") { Task { await model.requestAccess() } }
                    .buttonStyle(PillButtonStyle())
            case .denied:
                Text("Calendar access is off, so busy days aren't shown.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(PillButtonStyle())
            case .granted:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
