import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let model: CalendarModel
    private var cancellables = Set<AnyCancellable>()
    var iconStyle: IconStyle = .date { didSet { updateIcon() } }
    var menuProvider: () -> NSMenu = { AppMenu.make() }

    init(model: CalendarModel) {
        self.model = model
        super.init()

        let hosting = NSHostingController(rootView: PopoverView().environmentObject(model))
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        model.$today.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateIcon() }
        }.store(in: &cancellables)
        updateIcon()
    }

    func updateIcon() {
        let day = model.calendar.component(.day, from: model.today)
        statusItem.button?.image = StatusIcon.image(day: day, style: iconStyle)
        statusItem.button?.toolTip = model.today.formatted(date: .complete, time: .omitted)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        model.goToToday()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func closePopover() { popover.performClose(nil) }

    func showMenu() {
        guard let button = statusItem.button else { return }
        popover.performClose(nil)
        let menu = menuProvider()
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }
}
