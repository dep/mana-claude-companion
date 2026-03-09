import Foundation
import Combine

class CompanionStateManager: ObservableObject {
    @Published var currentState: CompanionState = .idle
    var currentPrompt: String?

    private let hookMonitor = HookStateMonitor()
    private var doneTimer: Timer?
    private var spinReturnState: CompanionState = .idle

    private let doneRevertDelay: TimeInterval = 3.0

    func startMonitoring() {
        hookMonitor.onStateChange = { [weak self] state, prompt in
            self?.handleStateChange(state, prompt: prompt)
        }
        hookMonitor.start()
    }

    func stopMonitoring() {
        hookMonitor.stop()
    }

    private func handleStateChange(_ state: String, prompt: String? = nil) {
        switch state {
        case "working":
            doneTimer?.invalidate()
            doneTimer = nil
            currentPrompt = prompt
            transition(to: .working)
        case "needsInput":
            doneTimer?.invalidate()
            doneTimer = nil
            transition(to: .needsInput)
        case "success":
            transition(to: .success)
            doneTimer?.invalidate()
            doneTimer = Timer.scheduledTimer(withTimeInterval: doneRevertDelay, repeats: false) { [weak self] _ in
                self?.transition(to: .idle)
            }
        case "idle":
            doneTimer?.invalidate()
            doneTimer = nil
            transition(to: .idle)
        default:
            break
        }
    }

    func spin() {
        guard currentState != .spinning else { return }
        spinReturnState = currentState
        transition(to: .spinning)
    }

    func finishedSpinning() {
        transition(to: spinReturnState)
    }

    func reset() {
        doneTimer?.invalidate()
        doneTimer = nil
        spinReturnState = .idle
        hookMonitor.resetLastEmitted()
        // Force re-read from disk so we resync with the hook monitor
        if let raw = try? String(contentsOfFile: hookMonitor.stateFilePath, encoding: .utf8) {
            let state = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let mapped: CompanionState = switch state {
            case "working":    .working
            case "success":    .success
            case "needsInput": .needsInput
            default:           .idle
            }
            DispatchQueue.main.async { self.currentState = mapped }
        } else {
            DispatchQueue.main.async { self.currentState = .idle }
        }
    }

    private func transition(to newState: CompanionState) {
        guard newState != currentState else { return }
        DispatchQueue.main.async {
            self.currentState = newState
            SoundManager.shared.onStateChange(to: newState)
        }
    }
}
