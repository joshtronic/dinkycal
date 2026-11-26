import AppKit

@MainActor
enum AppMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Dinky Cal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }
}
