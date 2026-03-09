import Foundation

class HookStateMonitor {
    var onStateChange: ((String, String?) -> Void)?

    private var eventStream: FSEventStreamRef?
    let stateFilePath: String
    private let promptFilePath: String
    private var lastEmittedState: String?
    private var debounceWorkItem: DispatchWorkItem?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        stateFilePath = home.appendingPathComponent(".claude/companion-state").path
        promptFilePath = home.appendingPathComponent(".claude/companion-prompt").path
    }

    func start() {
        ensureStateFileExists()
        startStream()
    }

    func resetLastEmitted() {
        lastEmittedState = nil
    }

    func stop() {
        guard let stream = eventStream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
    }

    private func ensureStateFileExists() {
        let dir = (stateFilePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: stateFilePath) {
            try? "idle".write(toFile: stateFilePath, atomically: true, encoding: .utf8)
        }
    }

    private func startStream() {
        let dir = (stateFilePath as NSString).deletingLastPathComponent as CFString
        let pathsToWatch = [dir] as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        let stream = FSEventStreamCreate(
            nil,
            { _, info, _, _, _, _ in
                guard let info else { return }
                let monitor = Unmanaged<HookStateMonitor>.fromOpaque(info).takeUnretainedValue()
                monitor.scheduleRead()
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            flags
        )

        guard let stream else { return }
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        eventStream = stream
    }

    private func scheduleRead() {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.readAndEmitState()
        }
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: item)
    }

    private func readAndEmitState() {
        guard let raw = try? String(contentsOfFile: stateFilePath, encoding: .utf8) else { return }
        let state = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        NSLog("[HookStateMonitor] read state='\(state)' lastEmitted='\(lastEmittedState ?? "nil")'")
        guard state != lastEmittedState else { return }
        lastEmittedState = state
        NSLog("[HookStateMonitor] emitting state='\(state)'")
        let prompt: String? = if state == "working",
            let p = try? String(contentsOfFile: promptFilePath, encoding: .utf8),
            !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            p.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            nil
        }
        onStateChange?(state, prompt)
    }
}
