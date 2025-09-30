import SwiftUI
import AVFoundation

struct GachaEffectView: View {
    let result: GachaViewModel.Result
    var sessionBubbleStarEarned: Int = 0
    var showResultWindow: Bool = true
    var onFinish: () -> Void

    @State private var bubbleRise = false
    @State private var showBubble = true
    @State private var showFlash = false
    @State private var showBackground = false
    @State private var showMonster = false
    @State private var showSilhouette = false
    @State private var showWhiteFlash = false
    @State private var silhouetteOpacity: Double = 0
    @State private var showResult = false
    @State private var allowSkip = false
    @State private var showShockwave = false
    @State private var showPreBurst = false
    @State private var audioPlayer: AVAudioPlayer?

    private var rarity: Int { result.record.rarity }
    private var rarityColor: Color {
        switch rarity {
        case 1: return .blue
        case 2: return .green
        case 3: return .purple
        case 4: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Image("GachaBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(nil, value: showBackground)

            if showBubble {
                Image("bubble_rare\(rarity)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(y: bubbleRise ? -120 : 200)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5)) {
                            bubbleRise = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showBubble = false }
                            showShockwave = true
                            showPreBurst = true
                            playGachaSound()
                            showFlash = true
                            startSilhouettePhase()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation { showShockwave = false }
                                showPreBurst = false
                                withAnimation { showFlash = false }
                            }
                        }
                    }
            }

            if showShockwave {
                ShockwaveView(color: rarityColor)
                    .frame(width: 160, height: 160)
            }
            if showPreBurst {
                StarBurstView(color: rarityColor)
                    .frame(width: 160, height: 160)
            }

            if showFlash {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Image("flash_rare\(rarity)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 980, height: 980)
                            .transition(.opacity)
                    )
                    .allowsHitTesting(false)
            }

            if showSilhouette {
                Image(result.record.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .colorMultiply(.black)
                    .opacity(silhouetteOpacity)
            }

            if showWhiteFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showBackground {
                Image("appear_rare\(rarity)")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            if showMonster {
                ZStack {
                    if result.isNew {
                        StarBurstView(color: rarityColor)
                            .frame(width: 280, height: 280)
                    }
                    Image(result.record.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }

            if showResult && showResultWindow {
                VStack(spacing: 12) {
                    Image(result.record.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                    if sessionBubbleStarEarned > 0 {
                        Text("獲得した泡沫星：\(sessionBubbleStarEarned)個")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    Button("閉じる") {
                        onFinish()
                    }
                }
                .padding(24)
                .background(.thinMaterial)
                .cornerRadius(12)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if allowSkip && result.isNew && showMonster {
                if showResultWindow {
                    withAnimation {
                        showMonster = false
                        showBackground = false
                        showResult = true
                    }
                } else {
                    onFinish()
                }
            }
        }
    }

    private func playGachaSound() {
        guard let path = Bundle.main.path(forResource: "GachaEffect", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    private func startSilhouettePhase() {
        showSilhouette = true
        silhouetteOpacity = 0
        DispatchQueue.main.async {
            withAnimation(.easeIn(duration: 1)) {
                silhouetteOpacity = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSilhouette = false }
            if result.isNew {
                showWhiteFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { showWhiteFlash = false }
                    startMonsterPhase()
                }
            } else {
                if showResultWindow {
                    withAnimation {
                        showResult = true
                    }
                } else {
                    onFinish()
                }
            }
        }
    }

    private func startMonsterPhase() {
        if result.isNew {
            withAnimation { showBackground = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showMonster = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                allowSkip = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if showResultWindow {
                    withAnimation {
                        showMonster = false
                        showBackground = false
                        showResult = true
                    }
                } else {
                    onFinish()
                }
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showMonster = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if showResultWindow {
                    withAnimation { showResult = true }
                } else {
                    onFinish()
                }
            }
        }
    }
}

