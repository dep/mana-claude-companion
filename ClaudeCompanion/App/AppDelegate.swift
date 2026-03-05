import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: CompanionPanel?
    private var menuBarManager: MenuBarManager?
    let stateManager = CompanionStateManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        panel = CompanionPanel(stateManager: stateManager)
        panel?.orderFront(nil)

        menuBarManager = MenuBarManager(panel: panel!)

        stateManager.startMonitoring()

        // Register as login item on first launch
        if !LoginItemManager.shared.isEnabled {
            LoginItemManager.shared.enable()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
