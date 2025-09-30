import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

final class AudioCache {
    static let shared = AudioCache()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
#if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clear),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
#endif
    }

    func player(forPath path: String) -> AVAudioPlayer? {
        if let existing = players[path] {
            return existing
        }
        let url = URL(fileURLWithPath: path)
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        player.prepareToPlay()
        players[path] = player
        return player
    }

    @objc func clear() {
        players.removeAll()
    }
}
