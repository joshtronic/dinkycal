import AppKit
import ServiceManagement
import SwiftUI

/// The right-click / gear menu, plus the Preferences and About windows it opens.
@MainActor
final class AppMenu: NSObject {
    private let model: CalendarModel
    #if !DIRECT_DISTRIBUTION
    let tipJar = TipJar()
    private var tipWindow: NSWindow?
    #endif
    private var preferencesWindow: NSWindow?
    private var aboutWindow: NSWindow?

    init(model: CalendarModel) {
        self.model = model
    }

    func make() -> NSMenu {
        let menu = NSMenu()
        if !model.isOnCurrentMonth {
            menu.addItem(item("Today", #selector(goToToday)))
            menu.addItem(.separator())
        }
        let login = item("Launch at Login", #selector(toggleLaunchAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(item("Settings…", #selector(openPreferences), key: ","))
        menu.addItem(item("About Dinky Cal", #selector(openAbout)))
        menu.addItem(item("Support Dinky Cal…", #selector(openSupport)))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Dinky Cal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func goToToday() { model.goToToday() }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.toggle()
    }

    @objc func openPreferences() {
        preferencesWindow = show(preferencesWindow, title: "Dinky Cal Settings") {
            PreferencesView()
                .environmentObject(self.model)
                .environmentObject(self.model.preferences)
        }
    }

    @objc func openAbout() {
        #if DIRECT_DISTRIBUTION
        aboutWindow = show(aboutWindow, title: "About Dinky Cal") { AboutView(isSupporter: false) }
        #else
        aboutWindow = show(aboutWindow, title: "About Dinky Cal") { AboutView(isSupporter: self.tipJar.isSupporter) }
        #endif
    }

    /// App Store build: the tip jar. Direct build: GitHub Sponsors (StoreKit isn't available there).
    @objc func openSupport() {
        #if DIRECT_DISTRIBUTION
        NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/joshtronic")!)
        #else
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "previewTips") { tipJar.showPreviewItems() }
        #endif
        tipWindow = show(tipWindow, title: "Support Dinky Cal") { TipJarView(tipJar: self.tipJar) }
        #endif
    }

    private func show<V: View>(_ existing: NSWindow?, title: String, content: () -> V) -> NSWindow {
        let window = existing ?? {
            let hosting = NSHostingController(rootView: content())
            hosting.sizingOptions = .preferredContentSize
            let window = NSWindow(contentViewController: hosting)
            window.title = title
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            return window
        }()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        return window
    }
}

enum LaunchAtLogin {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    @MainActor
    static func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
                // macOS may want the user to approve the login item first.
                if SMAppService.mainApp.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn't change Launch at Login"
            alert.runModal()
        }
    }
}
