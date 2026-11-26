import AppKit
import Combine

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
    private var statusController: StatusItemController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences = Preferences()
        model = CalendarModel(store: EventStoreService(), preferences: preferences)
        statusController = StatusItemController(model: model)
        statusController.iconStyle = preferences.iconStyle
        preferences.$iconStyle
            .sink { [weak self] style in self?.statusController.iconStyle = style }
            .store(in: &cancellables)
        #if DEBUG
        // Debug-only hook for screenshots: `open DinkyCal.app --args -openPopover YES`
        if UserDefaults.standard.bool(forKey: "openPopover") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.statusController.showPopover()
            }
        }
        #endif

        let refresh: (Notification) -> Void = { [weak self] _ in
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
