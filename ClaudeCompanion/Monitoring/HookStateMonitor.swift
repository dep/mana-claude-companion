import Foundation

class HookStateMonitor {
    var onStateChange: ((String) -> Void)?

    private var eventStream: FSEventStreamRef?
    private let stateFilePath: String
    private var lastEmittedState: String?

    init() {
        stateFilePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/companion-state").path
    }

    func start() {
        ensureStateFileExists()
        startStream()
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
                monitor.readAndEmitState()
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

    private func readAndEmitState() {
        guard let raw = try? String(contentsOfFile: stateFilePath, encoding: .utf8) else { return }
        let state = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state != lastEmittedState else { return }
        lastEmittedState = state
        onStateChange?(state)
    }
}
