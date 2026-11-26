import AppKit
import Combine
import SwiftUI
import KeyboardShortcuts

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var delegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        Self.delegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    private var preferences: Preferences!
    private var cancellables = Set<AnyCancellable>()
    private var model: CalendarModel!
    private var appMenu: AppMenu!
    private var statusController: StatusItemController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences = Preferences()
        model = CalendarModel(store: EventStoreService(), preferences: preferences)
        statusController = StatusItemController(model: model)
        statusController.iconStyle = preferences.iconStyle
        appMenu = AppMenu(model: model)
        statusController.menuProvider = { [unowned self] in self.appMenu.make() }
        KeyboardShortcuts.onKeyUp(for: .togglePopover) { [weak self] in
            self?.statusController.togglePopover()
        }
        preferences.$iconStyle
            .sink { [weak self] style in self?.statusController.iconStyle = style }
            .store(in: &cancellables)
        #if DEBUG
        // Debug-only: `--args -snapshot YES` renders the popover to <container tmp>/popover.png and quits.
        if UserDefaults.standard.bool(forKey: "snapshot") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                let hover = UserDefaults.standard.integer(forKey: "previewHoverDays")
                if hover != 0 { self.model.hoveredDay = self.model.calendar.date(byAdding: .day, value: hover, to: self.model.today) }
                let view = PopoverView()
                    .environmentObject(self.model)
                    .environmentObject(self.preferences)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, UserDefaults.standard.bool(forKey: "light") ? .light : .dark)
                if UserDefaults.standard.bool(forKey: "dumpEvents") {
                    let names = Dictionary(uniqueKeysWithValues: self.model.store.calendars().map { ($0.id, $0.title) })
                    for e in self.model.events.sorted(by: { $0.start < $1.start }) {
                        print("DUMP", names[e.calendarID] ?? "?", "|", e.isAllDay ? "ALLDAY" : "timed", e.isFree ? "free" : "busy", "|", e.start.formatted(date: .abbreviated, time: .shortened), "→", e.end.formatted(date: .abbreviated, time: .shortened), "|", e.title)
                    }
                }
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                if let tiff = renderer.nsImage?.tiffRepresentation,
                   let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    let path = UserDefaults.standard.string(forKey: "snapshotPath")
                        ?? FileManager.default.temporaryDirectory.appendingPathComponent("popover.png").path
                    try? png.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
        // Debug-only hook for screenshots: `open DinkyCal.app --args -openPopover YES`
        if ["openPopover", "openSettings", "openAbout"].contains(where: UserDefaults.standard.bool(forKey:)) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                if UserDefaults.standard.bool(forKey: "openSettings") { self.appMenu.openPreferences() }
                if UserDefaults.standard.bool(forKey: "openAbout") { self.appMenu.openAbout() }
                self.statusController.showPopover()
                let hover = UserDefaults.standard.integer(forKey: "previewHoverDays")
                if hover != 0, let day = self.model.calendar.date(byAdding: .day, value: hover, to: self.model.today) {
                    self.model.hoveredDay = day
                }
            }
        }
        #endif

        let refresh: @Sendable (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.model.refreshToday() }
        }
        let center = NotificationCenter.default
        center.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main, using: refresh)
        center.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main, using: refresh)
        center.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main, using: refresh)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: refresh)
    }
}
