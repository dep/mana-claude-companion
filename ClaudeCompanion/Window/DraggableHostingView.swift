import AppKit
import SwiftUI

class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var dragStartScreen: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

    override func mouseDown(with event: NSEvent) {
        dragStartScreen = event.locationInWindow
            .applying(.init(translationX: window?.frame.minX ?? 0, y: window?.frame.minY ?? 0))
        dragStartWindowOrigin = window?.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window,
              let startScreen = dragStartScreen,
              let startOrigin = dragStartWindowOrigin else { return }
        let currentScreen = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(
            x: startOrigin.x + currentScreen.x - startScreen.x,
            y: startOrigin.y + currentScreen.y - startScreen.y
        ))
    }

    override func mouseUp(with event: NSEvent) {
        (window as? CompanionPanel)?.savePosition()
        dragStartScreen = nil
        dragStartWindowOrigin = nil
    }
}
