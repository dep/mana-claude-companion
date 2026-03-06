import AVFoundation
import AppKit

class SoundManager {
    static let shared = SoundManager()

    private var loopSound: NSSound?
    private var oneShots: [AVAudioPlayer] = []

    private init() {}

    func play(_ name: String, loop: Bool = false) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            NSLog("[SoundManager] Missing sound: \(name)")
            return
        }
        if loop {
            stopLoop()
            guard let sound = NSSound(contentsOf: url, byReference: false) else {
                NSLog("[SoundManager] NSSound failed to load: \(name)")
                return
            }
            sound.loops = true
            sound.volume = 1.0
            let ok = sound.play()
            NSLog("[SoundManager] loop play(\(name)) started=\(ok)")
            loopSound = sound
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.8
                let ok = player.play()
                NSLog("[SoundManager] one-shot play(\(name)) started=\(ok)")
                oneShots.append(player)
                oneShots.removeAll { !$0.isPlaying && $0 !== player }
            } catch {
                NSLog("[SoundManager] one-shot player error for \(name): \(error)")
            }
        }
    }

    func stopLoop() {
        loopSound?.stop()
        loopSound = nil
    }

    func onStateChange(to state: CompanionState) {
        switch state {
        case .working:
            let taskStartSounds = [
                "quiet_quiet_ok.wav",
                "quiet_okie-dokie.mp3",
                "quiet_hmm-whatever.mp3",
                "quiet_hmm-ok-2.mp3",
                "quiet_hmm-ok-1.mp3",
            ]
            play(taskStartSounds.randomElement()!)
            play("quiet_quiet_quiet_music.mp3", loop: true)
        case .needsInput:
            stopLoop()
            play("quiet_quiet_hmmm.mp3")
        case .success:
            stopLoop()
            let finishedSounds = [
                "quiet_quiet_all-done.mp3",
                "quiet_there-you-go.mp3",
                "quiet_finished.mp3",
            ]
            play(finishedSounds.randomElement()!)
        case .idle, .spinning:
            stopLoop()
        }
    }

    func onTap() {
        play("quiet_quiet_giggle.mp3")
    }
}
