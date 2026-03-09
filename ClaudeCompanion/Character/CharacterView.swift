import SwiftUI
import AppKit

struct CharacterView: View {
    @ObservedObject var stateManager: CompanionStateManager
    @State private var bubbleMessage: String = ""
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ZStack {
                    if bubbleOpacity > 0 {
                        SpeechBubbleView(message: bubbleMessage)
                            .opacity(bubbleOpacity)
                            .transition(.opacity)
                    }
                }
                .frame(height: 65)

                Group {
                    if stateManager.currentState == .spinning {
                        VideoPlayerView(name: "spin", loop: false) {
                            stateManager.finishedSpinning()
                        }
                    } else {
                        VideoPlayerView(name: animationName(for: stateManager.currentState))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    SoundManager.shared.onTap()
                    if stateManager.currentState == .spinning {
                        stateManager.reset()
                    } else {
                        stateManager.spin()
                    }
                }
                .contextMenu {
                    Button("Hide") { NSApp.hide(nil) }
                    Divider()
                    Button("Quit Claude Companion") { NSApp.terminate(nil) }
                }
            }

            ResizeHandle()
                .frame(width: 24, height: 24)
        }
        .onChange(of: stateManager.currentState) { newState in
            NSLog("[CharacterView] onChange fired: \(newState)")
            if newState == .working || newState == .success {
                showBubble(for: newState)
            } else {
                dismissBubble()
            }
        }
    }

    private func animationName(for state: CompanionState) -> String {
        switch state {
        case .idle:       return "meditating"
        case .working:    return "working"
        case .success:    return "dancing"
        case .needsInput: return "thinking"
        case .spinning:   return "spin"
        }
    }

    private func showBubble(for state: CompanionState) {
        bubbleTask?.cancel()
        bubbleMessage = SpeechMessages.random(for: state)
        let prompt = stateManager.currentPrompt

        bubbleTask = Task {
            async let quip = ClaudeService.shared.fetchQuip(for: state, userPrompt: prompt)
            withAnimation(.easeIn(duration: 0.2)) { bubbleOpacity = 1 }
            if let fetched = await quip, !Task.isCancelled {
                bubbleMessage = fetched
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) { bubbleOpacity = 0 }
        }
    }

    private func dismissBubble() {
        bubbleTask?.cancel()
        withAnimation(.easeOut(duration: 0.4)) { bubbleOpacity = 0 }
    }
}

struct ResizeHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizeHandleView {
        ResizeHandleView()
    }
    func updateNSView(_ nsView: ResizeHandleView, context: Context) {}
}

class ResizeHandleView: NSView {
    private var dragStart: NSPoint?
    private var startFrame: NSRect?

    override init(frame: NSRect) {
        super.init(frame: frame)
        let cursor = NSCursor.init(image: NSCursor.crosshair.image, hotSpot: .zero)
        addCursorRect(bounds, cursor: cursor)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(1.5)
        let pad: CGFloat = 3
        let size: CGFloat = 10
        for i in 0..<3 {
            let offset = CGFloat(i) * 4
            ctx.move(to: CGPoint(x: bounds.maxX - pad - offset, y: bounds.minY + pad))
            ctx.addLine(to: CGPoint(x: bounds.maxX - pad, y: bounds.minY + pad + offset))
        }
        ctx.strokePath()
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        startFrame = window?.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let dragStart, let startFrame else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - dragStart.x
        let dy = -(current.y - dragStart.y)
        let delta = (abs(dx) > abs(dy)) ? dx : dy
        let newSize = max(startFrame.width + delta, CompanionPanel.minSize)
        let newHeight = newSize + 65
        let newOriginY = startFrame.maxY - newHeight
        window.setFrame(
            NSRect(x: startFrame.minX, y: newOriginY, width: newSize, height: newHeight),
            display: true
        )
    }

    override func mouseUp(with event: NSEvent) {
        (window as? CompanionPanel)?.saveSize()
        (window as? CompanionPanel)?.savePosition()
        dragStart = nil
        startFrame = nil
    }
}
