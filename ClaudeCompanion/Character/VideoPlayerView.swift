import SwiftUI
import AVFoundation

struct VideoPlayerView: NSViewRepresentable {
    let name: String
    var loop: Bool = true
    var onFinished: (() -> Void)? = nil

    func makeNSView(context: Context) -> AlphaVideoPlayerView {
        let view = AlphaVideoPlayerView()
        view.load(name: name, loop: loop, onFinished: onFinished)
        return view
    }

    func updateNSView(_ nsView: AlphaVideoPlayerView, context: Context) {
        if nsView.currentName != name {
            nsView.load(name: name, loop: loop, onFinished: onFinished)
        }
    }
}

class AlphaVideoPlayerView: NSView {
    var currentName: String = ""

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loop: Bool = true
    private var onFinished: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
    }

    override var isOpaque: Bool { false }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    func load(name: String, loop: Bool = true, onFinished: (() -> Void)? = nil) {
        currentName = name
        self.loop = loop
        self.onFinished = onFinished

        player?.pause()
        playerLayer?.removeFromSuperlayer()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        guard let url = Bundle.main.url(forResource: name, withExtension: "mov") else { return }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = true
        player = newPlayer

        let newLayer = AVPlayerLayer(player: newPlayer)
        newLayer.frame = bounds
        newLayer.videoGravity = .resizeAspect
        newLayer.backgroundColor = CGColor.clear
        newLayer.isOpaque = false
        newLayer.pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        layer?.addSublayer(newLayer)
        playerLayer = newLayer

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish),
                                               name: .AVPlayerItemDidPlayToEndTime, object: item)

        newPlayer.play()
    }

    @objc private func playerDidFinish() {
        if loop {
            player?.seek(to: .zero)
            player?.play()
        } else {
            onFinished?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
