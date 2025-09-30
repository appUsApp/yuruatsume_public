import SwiftUI
import AVFoundation

struct MonsterAppearEffectView: View {
    let monster: Monster
    var onDefeat: (() -> Void)?

    @State private var fadeOut = false
    @State private var tapsRemaining = 3
    @State private var canTap = true
    @State private var dimmed = false
    @State private var showCelebration = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            AppearEffectView(
                imageName: monster.imageName,
                size: 96,
                initialScale: 1.0,
                targetScale: 1.5,
                bounceOffset: -30,
                bounceDuration: 1,
                tapEnabledDelay: 0.5,
                fadeOutDelay: nil,
                onTap: handleTap,
                fadeOut: $fadeOut
            )
            .opacity(dimmed ? 0.5 : 1.0)

            if showCelebration {
                StarBurstView()
            }
        }
        .onAppear { playAppearSound() }
    }

    private func playAppearSound() {
        guard let path = Bundle.main.path(forResource: "sandyRarity1", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    private func playTapSound(index: Int) {
        let fileName = "MonsterTouch\(index)"
        guard let path = Bundle.main.path(forResource: fileName, ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    private func handleTap() {
        guard canTap && tapsRemaining > 0 else { return }
        tapsRemaining -= 1
        let tapIndex = 3 - tapsRemaining
        playTapSound(index: tapIndex)
        let base = hapticLevelForDiscovery(rarity: MonsterData.rarity(for: "\(monster.id)"), isItem: false)
        let level = hapticLevelForTap(base: base, tapIndex: tapIndex)
        triggerHaptic(level)
        canTap = false
        dimmed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dimmed = false
            if tapsRemaining == 0 {
                showCelebration = true
                withAnimation { fadeOut = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showCelebration = false
                    onDefeat?()
                }
            } else {
                canTap = true
            }
        }
    }
}

