import SwiftUI
import AVFoundation

struct GachaView: View {
    var onClose: () -> Void
    @State private var player: AVAudioPlayer?
    @State private var sfxPlayer: AVAudioPlayer? = nil
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @EnvironmentObject private var gachaVM: GachaViewModel
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager
    @EnvironmentObject private var listeners: FirestoreListeners
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var context
    @State private var showEffect = false
    @State private var currentResult: GachaViewModel.Result?
    @State private var showMultiEffect = false
    @State private var multiResults: [GachaViewModel.Result] = []
    @State private var sessionBubbleStarEarned: Int = 0
    @State private var bubbleStarPersisted: Bool = false
    @State private var showConfirm = false
    @State private var confirmCount: Int = 0
    @State private var confirmCost: Int = 0
    @State private var confirmType: GachaViewModel.GachaType = .premium
    @State private var showPurchaseView = false
    @State private var infoType: GachaViewModel.GachaType?
    @AppStorage("GachaView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    private let bubbleStarRewardByRarity = [1:1, 2:5, 3:10, 4:30, 5:100]

    private func infoCard(imageName: String,
                          description: String,
                          type: GachaViewModel.GachaType) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                Text(description)
                    .font(.caption)
                gachaButtons(type: type)
            }
            Button {
                SoundEffect.play("Button", player: &sfxPlayer)
                infoType = type
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private func gachaButtons(type: GachaViewModel.GachaType) -> some View {
        HStack(spacing: 16) {
            Button("1連") {
                SoundEffect.play("Button", player: &sfxPlayer)
                confirmType = type
                confirmCount = 1
                confirmCost = 5
                showConfirm = true
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("10連") {
                SoundEffect.play("Button", player: &sfxPlayer)
                confirmType = type
                confirmCount = 10
                confirmCost = 50
                showConfirm = true
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.pink.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }

    private func performGacha(type: GachaViewModel.GachaType, count: Int, cost: Int) async {
        sessionBubbleStarEarned = 0
        bubbleStarPersisted = false
        guard let uid = authService.uid else { return }
        let success = await CurrencyService.shared.purchase(.bubbleCrystal, cost: cost, uid: uid)
        guard success else { return }
        let results = gachaVM.draw(type: type, count: count)
        for result in results {
            if !result.isNew {
                sessionBubbleStarEarned += bubbleStarRewardByRarity[result.record.rarity] ?? 1
            }
        }
        await persistBubbleStarIncrement(sessionBubbleStarEarned)
        if count == 1 {
            currentResult = results.first
            showEffect = currentResult != nil
        } else {
            multiResults = results
            showMultiEffect = !multiResults.isEmpty
        }
    }

    private func persistBubbleStarIncrement(_ amount: Int) async {
        guard amount > 0, !bubbleStarPersisted, let uid = authService.uid else { return }
        do {
            try await CurrencyService.shared.increment(.bubbleStar, by: amount, uid: uid)
            bubbleStarPersisted = true
        } catch {
            print("bubbleStar increment failed: \(error)")
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("")
                    .font(.headline)
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    infoCard(
                        imageName: "Gacha_premium",
                        description: "シオノコがランダムに登場するガチャ",
                        type: .premium
                    )

                    infoCard(
                        imageName: "Gacha_pickUp",
                        description: "砂浜に生息するシオノコのみのガチャ",
                        type: .pickup
                    )
                }
                .padding(.top, 60)
                Spacer()
                Button {
                    SoundEffect.play("Button", player: &sfxPlayer)
                    showPurchaseView = true
                } label: {
                    Image("purchase_banner")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.66)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .padding(.top, 70)
            .padding(.horizontal)
            // The effect view is presented via fullScreenCover

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        SoundEffect.play("Button", player: &sfxPlayer)
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 72)
                .padding(.horizontal)
                Spacer()
            }
            if showConfirm {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                GachaConfirmPopupView(pullCount: confirmCount,
                                      cost: confirmCost,
                                      canAfford: (listeners.user?.currencies.bubbleCrystal ?? 0) >= confirmCost,
                                      onCancel: { showConfirm = false },
                                      onConfirm: {
                                          showConfirm = false
                                          Task { await performGacha(type: confirmType, count: confirmCount, cost: confirmCost) }
                                      })
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "ガチャ",
                    messages: [
                        "ガチャでシオノコを当てて、ビーチに出そう！",
                        "当てて、ビーチで見つけたシオノコはギャラリーに登録される！",
                        "すでに当てているシオノコと出会った時にはショップで使える泡沫星を置いていくよ！"
                    ]
                ) {
                    withAnimation {
                        hasSeenGuide = true
                        showGuide = false
                    }
                }
                .transition(.opacity)
            }
        }
        .background(
            Image("GachaSelectBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            )
        .onAppear {
            gachaVM.context = context
            initializeMonstersIfNeeded(context: context)
            timeManager.shouldOverrideBGM = true
            timeManager.stopBGM()
            if let path = Bundle.main.path(forResource: "Gacha", ofType: "caf") {
                let url = URL(fileURLWithPath: path)
                player = try? AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.play()
            }
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }
        .onDisappear {
            player?.stop()
            timeManager.resumeBGM()
        }
        .sheet(item: $infoType) { type in
            GachaInfoView(type: type,
                          rarityRates: gachaVM.rarityRateInfo)
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showEffect) {
            if let result = currentResult {
                GachaEffectView(result: result,
                                sessionBubbleStarEarned: sessionBubbleStarEarned) {
                    showEffect = false
                    currentResult = nil
                }
                .interactiveDismissDisabled() // prevent swipe to dismiss
            }
        }
        .fullScreenCover(isPresented: $showMultiEffect) {
            MultiGachaEffectView(results: multiResults,
                                 sessionBubbleStarEarned: sessionBubbleStarEarned) {
                showMultiEffect = false
                multiResults = []
            }
            .id(multiResults.map { $0.record.monsterId }.hashValue)
            .interactiveDismissDisabled()
        }
    }
}

private struct GachaConfirmPopupView: View {
    let pullCount: Int
    let cost: Int
    var canAfford: Bool
    var onCancel: () -> Void
    var onConfirm: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var showError = false
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack {
                        Spacer()
                        Text("\(pullCount)連ガチャを行いますか？\n消費泡沫結晶：\(cost)個")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .padding(.horizontal, 16)
                        Spacer()
                        if showError {
                            Text("泡沫結晶が不足しています")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        HStack(spacing: 16) {
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onCancel()
                            }) {
                                Image("Cancel Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                if canAfford {
                                    onConfirm()
                                } else {
                                    showError = true
                                }
                            }) {
                                Image("OK Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }
                        }
                        .padding(.bottom, 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                }
        }
    }
}

private struct GachaInfoView: View {
    struct MonsterInfo: Identifiable {
        let id: Int
        let rawName: String
        let rarity: Int

        var displayName: String {
            let name = MonsterData.displayName(for: id)
            return name.isEmpty ? rawName : name
        }
    }

    let type: GachaViewModel.GachaType
    let rarityRates: [(rarity: Int, rate: Double)]
    @Environment(\.dismiss) private var dismiss

    private var title: String {
        switch type {
        case .premium: return "プレミアムガチャ情報"
        case .pickup: return "ピックアップガチャ情報"
        }
    }

    private var monsterNames: [String] {
        switch type {
        case .premium: return MonsterData.all
        case .pickup: return MonsterData.sand
        }
    }

    private var monstersByRarity: [(rarity: Int, monsters: [MonsterInfo])] {
        let infos = monsterNames.compactMap { name -> MonsterInfo? in
            let id = MonsterData.id(for: name)
            guard id >= 0 else { return nil }
            return MonsterInfo(id: id,
                               rawName: name,
                               rarity: MonsterData.rarity(for: name))
        }
        let grouped = Dictionary(grouping: infos, by: { $0.rarity })
        let sortedKeys = grouped.keys.sorted()
        return sortedKeys.map { rarity in
            let monsters = grouped[rarity]?.sorted { $0.displayName < $1.displayName } ?? []
            return (rarity: rarity, monsters: monsters)
        }
    }

    private var rateRows: [(rarity: Int, rate: Double)] {
        rarityRates.sorted { $0.rarity < $1.rarity }
    }

    private var descriptionText: String {
        switch type {
        case .premium:
            return "全てのシオノコが対象です。レアリティごとの排出率とモンスター一覧は以下の通りです。"
        case .pickup:
            return "砂浜に生息するシオノコのみが排出されます。レアリティごとの排出率とモンスター一覧は以下の通りです。"
        }
    }

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack { content }
            } else {
                NavigationView { content }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(descriptionText)
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    Text("排出確率")
                        .font(.headline)
                    ForEach(Array(rateRows.enumerated()), id: \.element.rarity) { index, row in
                        HStack {
                            Text("レアリティ\(row.rarity)")
                            Spacer()
                            Text(String(format: "%.1f%%", row.rate * 100))
                        }
                        .padding(.vertical, 4)
                        if index != rateRows.count - 1 {
                            Divider()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("排出されるモンスター")
                        .font(.headline)
                    ForEach(monstersByRarity, id: \.rarity) { rarity, monsters in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("レアリティ\(rarity)")
                                .font(.subheadline)
                                .bold()
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(monsters) { monster in
                                    Text(monster.displayName)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
}

extension GachaViewModel.GachaType: Identifiable {
    var id: String {
        switch self {
        case .premium: return "premium"
        case .pickup: return "pickup"
        }
    }
}
