import AVFoundation

enum SoundEffect {
    static func play(_ name: String, player: inout AVAudioPlayer?) {
        guard AudioSettings.isAudioEnabled else { return }
        guard let path = Bundle.main.path(forResource: name, ofType: "caf"),
              let p = AudioCache.shared.player(forPath: path) else {
            return
        }
        player = p
        if p.isPlaying {
            p.currentTime = 0
        }
        p.play()
    }
}
