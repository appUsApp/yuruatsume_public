import SwiftUI
import AVFoundation

struct FishAppearEffectView: View {
    let item: GameItem
    var onTap: ((GameItem) -> Void)?

    @State private var fadeOut = false
    @State private var audioPlayer: AVAudioPlayer?

    private func playSound() {
        let fileName = "sandyRarity\(item.rarity)"
        guard let path = Bundle.main.path(forResource: fileName, ofType: "caf") else {
            return
        }
        guard let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    var body: some View {
        AppearEffectView(
            imageName: item.imageName,
            size: 64,
            initialScale: 0.8,
            targetScale: 1.2,
            bounceOffset: -20,
            bounceDuration: 1.5,
            tapEnabledDelay: 0.5,
            fadeOutDelay: 4,
            onTap: { onTap?(item) },
            fadeOut: $fadeOut
        )
        .onAppear { playSound() }
    }
}

