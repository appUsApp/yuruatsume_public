import SwiftUI
import AVFoundation

struct MultiGachaEffectView: View {
    let results: [GachaViewModel.Result]
    let sessionBubbleStarEarned: Int
    var onFinish: () -> Void

    private struct BubbleState {
        var showBubble: Bool = true
        var showFlash: Bool = false
        var showSilhouette: Bool = false
        var silhouetteOpacity: Double = 0
        var showMonster: Bool = false
        var showShockwave: Bool = false
        var showPreBurst: Bool = false
    }

    @State private var states: [BubbleState]
    @State private var currentIndex = 0
    @State private var showSummary = false
    @State private var showWhiteFlash = false
    @State private var showAppearBackground = false
    @State private var appearRarity = 1
    @State private var overlayMonster: String?
    @State private var appearScale = false
    @State private var audioPlayer: AVAudioPlayer?

    private let summaryColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 72), spacing: 16)
    ]

    init(results: [GachaViewModel.Result], sessionBubbleStarEarned: Int, onFinish: @escaping () -> Void) {
        self.results = results
        self.sessionBubbleStarEarned = sessionBubbleStarEarned
        self.onFinish = onFinish
        _states = State(initialValue: Array(repeating: BubbleState(), count: results.count))
    }

    var body: some View {
        ZStack {
            Image("GachaBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(nil, value: showAppearBackground)

            if showAppearBackground, let monster = overlayMonster {
                ZStack {
                    Image("appear_rare\(appearRarity)")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    StarBurstView(color: color(for: appearRarity))
                        .frame(width: 200, height: 200)
                    Image(monster)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .scaleEffect(appearScale ? 1 : 0.5)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                                appearScale = true
                            }
                        }
                }
                .zIndex(1)
            }

            if showWhiteFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showSummary {
                VStack(spacing: 16) {
                    ScrollView {
                        LazyVGrid(columns: summaryColumns, alignment: .center, spacing: 16) {
                            ForEach(results.indices, id: \.self) { i in
                                VStack(spacing: 4) {
                                    Image(results[i].record.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                    if results[i].isNew {
                                        Text("NEW")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                                .frame(minWidth: 72)
                            }
                        }
                        .padding()
                    }
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
            } else {
                VStack(spacing: 16) {
                    let c = results.count
                    let row1End = min(3, c)
                    if row1End > 0 {
                        HStack(spacing: 16) {
                            ForEach(0..<row1End, id: \.self) { i in bubbleView(for: i) }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    let row2End = min(7, c)
                    if c > 3 {
                        HStack(spacing: 16) {
                            ForEach(3..<row2End, id: \.self) { i in bubbleView(for: i) }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    let row3End = min(10, c)
                    if c > 7 {
                        HStack(spacing: 16) {
                            ForEach(7..<row3End, id: \.self) { i in bubbleView(for: i) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                .transition(.opacity)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            resetAnimationState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { revealNext() }
        }
        // 結果が変わったら毎回リセット（同一ビューID再利用対策）
        .onChange(of: results.count) {
            resetAnimationState()
        }
    }
    
    /// 毎回の演出開始前に状態をクリーンに戻す
    private func resetAnimationState() {
        currentIndex = 0
        showSummary = false
        showWhiteFlash = false
        showAppearBackground = false
        overlayMonster = nil
        appearScale = false
        // 結果数に合わせてステート配列も作り直し
        states = Array(repeating: BubbleState(), count: results.count)
    }


    @ViewBuilder
    private func bubbleView(for index: Int) -> some View {
        // 両配列に index が存在しなければ描画しない（保険）
        if !(index < results.count && index < states.count) {
            EmptyView()
        } else {
            ZStack {
                
                if states[index].showBubble {
                    Image("bubble_rare\(results[index].record.rarity)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
                if states[index].showShockwave {
                    ShockwaveView(color: color(for: results[index].record.rarity))
                        .frame(width: 80, height: 80)
                }
                if states[index].showPreBurst {
                    StarBurstView(color: color(for: results[index].record.rarity))
                        .frame(width: 80, height: 80)
                }
                if states[index].showFlash {
                    Image("flash_rare\(results[index].record.rarity)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }
                if states[index].showSilhouette {
                    Image(results[index].record.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .colorMultiply(.black)
                        .opacity(states[index].silhouetteOpacity)
                }
                if states[index].showMonster {
                    ZStack {
                        if results[index].isNew {
                            StarBurstView(color: color(for: results[index].record.rarity))
                                .frame(width: 80, height: 80)
                        }
                        Image(results[index].record.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .transition(.opacity)
                    }
                }
            }
            .frame(width: 80, height: 80)
        }
    }
    private func revealNext() {
        if currentIndex >= results.count {
            withAnimation {
                showSummary = true
            }
            return
        }

        states[currentIndex].showBubble = false
        states[currentIndex].showShockwave = true
        states[currentIndex].showPreBurst = true
        states[currentIndex].showFlash = true
        states[currentIndex].showSilhouette = true
        states[currentIndex].silhouetteOpacity = 0
        withAnimation(.easeIn(duration: 0.5)) {
            states[currentIndex].silhouetteOpacity = 1
        }
        playGachaSound()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation { states[currentIndex].showShockwave = false }
            states[currentIndex].showPreBurst = false
            withAnimation { states[currentIndex].showFlash = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                states[currentIndex].showSilhouette = false
            }
            let result = results[currentIndex]
            if result.isNew {
                showWhiteFlash = true
                appearRarity = result.record.rarity
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { showWhiteFlash = false }
                    overlayMonster = result.record.imageName
                    appearScale = false
                    showAppearBackground = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation {
                            showAppearBackground = false
                            overlayMonster = nil
                        }
                        states[currentIndex].showMonster = true
                        currentIndex += 1
                        revealNext()
                    }
                }
            } else {
                states[currentIndex].showMonster = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentIndex += 1
                    revealNext()
                }
            }
        }
    }

    private func color(for rarity: Int) -> Color {
        switch rarity {
        case 1: return .blue
        case 2: return .green
        case 3: return .purple
        case 4: return .orange
        default: return .red
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
}
