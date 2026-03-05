import AppKit
import SwiftUI

class CompanionPanel: NSPanel {
    private static let positionKey = "companionWindowPosition"
    private static let sizeKey = "companionWindowSize"
    static let minSize: CGFloat = 200
    static let defaultSize: CGFloat = 200

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(stateManager: CompanionStateManager) {
        let size = CompanionPanel.savedSize()
        let contentSize = NSSize(width: size, height: size + 65)
        super.init(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        let hostingView = DraggableHostingView(
            rootView: CharacterView(stateManager: stateManager)
        )
        hostingView.frame = NSRect(origin: .zero, size: contentSize)
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView

        restorePosition()
    }

    func savePosition() {
        let origin = frame.origin
        UserDefaults.standard.set(
            ["x": Double(origin.x), "y": Double(origin.y)],
            forKey: Self.positionKey
        )
    }

    func saveSize() {
        UserDefaults.standard.set(Double(frame.width), forKey: Self.sizeKey)
    }

    static func savedSize() -> CGFloat {
        let saved = UserDefaults.standard.double(forKey: sizeKey)
        return saved > 0 ? max(CGFloat(saved), minSize) : defaultSize
    }

    private func restorePosition() {
        if let saved = UserDefaults.standard.dictionary(forKey: Self.positionKey),
           let x = saved["x"] as? Double,
           let y = saved["y"] as? Double {
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let r = screen.visibleFrame
            setFrameOrigin(NSPoint(x: r.maxX - frame.width - 20, y: r.minY + 20))
        }
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        savePosition()
    }
}
