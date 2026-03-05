import AppKit

class MenuBarManager {
    private var statusItem: NSStatusItem?
    private weak var panel: CompanionPanel?

    init(panel: CompanionPanel) {
        self.panel = panel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Claude Companion")
        }
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Show Companion", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: LoginItemManager.shared.isEnabled ? "Disable Launch at Login" : "Launch at Login",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggleLoginItem() {
        LoginItemManager.shared.toggle()
        buildMenu() // Refresh menu title
    }

    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            statusItem?.menu?.item(at: 0)?.title = "Show Companion"
        } else {
            panel.orderFront(nil)
            statusItem?.menu?.item(at: 0)?.title = "Hide Companion"
        }
    }
}
