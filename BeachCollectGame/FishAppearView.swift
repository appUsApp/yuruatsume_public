import SwiftUI
import AVFoundation
import SwiftData

struct FishAppearView: View {
    @Environment(\.modelContext) private var context
    @Query private var allItems: [GameItem]
    @Query private var ownedMaps: [OwnedMapItem]

    @StateObject private var viewModel = ItemCollectionViewModel()
    @StateObject private var monsterVM = MonsterCollectionViewModel()
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager

    @State private var message: String = "Tap on the sea!"
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var spawnedItem: GameItem? = nil
    @State private var spawnPosition: CGPoint = .zero
    @State private var spawnedMonster: Monster? = nil

    @State private var showTapParticles = false
    @State private var tapParticlesID = UUID()
    @State private var tapPosition: CGPoint = .zero

    @State private var screenSize: CGSize = .zero
    @State private var safeAreaTop: CGFloat = 0
    @State private var moveTimer: Timer? = nil
    @State private var monsterTimeoutTask: DispatchWorkItem?
    @AppStorage("FishAppearView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false
    
    
    private func rollItemFound() -> Bool {
        let r = Int.random(in: 1...100)
        if missionManager.isToolActive(.enmonite) {
            return r > 50
        }
        return r > 90
    }

    private func rollMonsterFound() -> Bool {
        let base = 1
        let multiplier = missionManager.isToolActive(.horasyuugou) ? 10 : 1
        let threshold = min(1500, base * multiplier)
        return Int.random(in: 1...1500) <= threshold
    }

    private func randomMonster() -> Monster? {
        let allowed = MonsterData.ford + MonsterData.fish
        let descriptor = FetchDescriptor<MonsterRecord>(
            predicate: #Predicate { allowed.contains($0.name) && $0.obtained }
        )
        if let records = try? context.fetch(descriptor), let record = records.randomElement() {
            let name = MonsterData.displayName(for: record.monsterId)
            return Monster(id: record.monsterId, name: name)
        }
        return nil
    }
    
    private func rollRarity() -> Int {
        let r = Int.random(in: 1...100)
        if missionManager.isToolActive(.luckypearl) {
            switch r {
            case 1...80: return 2
            case 81...95: return 3
            default: return 4
            }
        } else {
            switch r {
            case 1...80: return 1
            case 81...95: return 2
            case 96...99: return 3
            default: return 4
            }
        }
    }

    private func pickRandomItem(rarity: Int) -> GameItem? {
        let timeKey = "\(timeManager.current)"
        let filtered = allItems.filter { item in
            item.rarity == rarity &&
            item.appearLocations.contains("FishAppear") &&
            item.appearTimes.contains(timeKey)
        }
        if let result = filtered.randomElement() { return result }

        let sameRarity = allItems.filter { item in
            item.rarity == rarity &&
            item.appearLocations.contains("FishAppear")
        }
        return sameRarity.randomElement()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AnimatedBackgroundImage(imageName: timeManager.seaImageName)
                    .frame(width: geo.size.width,
                           height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                TimedMessageView(message: $message)
                    .position(x: geo.size.width/2, y: geo.size.height * 0.28)

                if showTapParticles {
                    ScratchParticleView()
                        .id(tapParticlesID)
                        .position(tapPosition)
                }

                if let monster = spawnedMonster {
                    MonsterAppearEffectView(monster: monster) {
                        monsterTimeoutTask?.cancel()
                        stopMonsterMovement()
                        spawnedMonster = nil
                        let result = monsterVM.registerDefeat(of: monster)
                        let count = result.0
                        missionManager.recordMonsterCatch(monster: monster, isNew: result.1)
                        if result.1 {
                            galleryBadge.registerNewContent(imageName: monster.imageName)
                        }
                        let target = missionManager.nextMonsterMissionTarget(count: count)
                        message = "\(monster.name)となかよくなった。（\(count) / \(target)）"
                    }
                    .position(spawnPosition)
                }

                if let item = spawnedItem {
                    FishAppearEffectView(item: item) { tapped in
                        if let updated = viewModel.acquire(tapped) {
                            missionManager.recordItemGet(updated)
                            if viewModel.lastGottenItemIsNew {
                                galleryBadge.registerNewContent(imageName: updated.imageName)
                            } else {
                                let bonuses = BonusItemManager.currentBonusItems(
                                    allItems: allItems,
                                    ownedMaps: ownedMaps,
                                    consumed: timeManager.consumedBonusItemIds
                                )
                                if bonuses.contains(where: { $0.itemId == updated.itemId }) {
                                    timeManager.consumeBonus(itemId: updated.itemId)
                                    missionManager.grantBonusMissionGold(duplicateGold: updated.duplicateGold, multiplier: 5)
                                } else {
                                    missionManager.gainMoney(updated.duplicateGold)
                                }
                            }
                            let count = updated.count
                            let target = missionManager.nextItemMissionTarget(item: updated, count: count)
                            message = "\(updated.name)を見つけた。（\(count) / \(target)）"
                        }
                        spawnedItem = nil
                    }
                    .position(spawnPosition)
                }
                if let got = viewModel.lastGottenItem, viewModel.lastGottenItemIsNew {
                    ItemGetOverlayView(item: got) {
                        viewModel.lastGottenItem = nil
                    }
                    .zIndex(2)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                            withAnimation {
                                viewModel.lastGottenItem = nil
                            }
                        }
                    }
                }

                if showGuide {
                    FirstVisitGuideView(
                        title: "海辺での探し方",
                        messages: [
                            "海ではタップで発見！"
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
            .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                tapPosition = location
                                triggerTapParticles()
                                if spawnedItem != nil || spawnedMonster != nil {
                                    return
                                }
                                spawnPosition = location
                                if rollMonsterFound(), let newMon = randomMonster() {
                                    spawnedMonster = newMon
                                    startMonsterMovement()
                                    scheduleMonsterTimeout()
                                    message = "シオノコだ！"
                                    let rarity = MonsterData.rarity(for: "\(newMon.id)")
                                    triggerHaptic(hapticLevelForDiscovery(rarity: rarity, isItem: false))
                                    return
                                }
                                if rollItemFound() {
                                    let rarity = rollRarity()
                                    message = "当たり！レア度: \(rarity)"
                                    print("hit rarity \(rarity)")
                                    if let newItem = pickRandomItem(rarity: rarity) {
                                        spawnedItem = newItem
                                        triggerHaptic(hapticLevelForDiscovery(rarity: rarity, isItem: true))
                                    }
                                } else {
                                }
                    }
            )
            .onAppear {
                screenSize = geo.size
                safeAreaTop = geo.safeAreaInsets.top
                viewModel.context = context
                monsterVM.context = context
                // 初回起動時はアイテムを登録
                initializeItemsIfNeeded(context: context)
                initializeMonstersIfNeeded(context: context)
                if !hasSeenGuide {
                    DispatchQueue.main.async {
                        withAnimation { showGuide = true }
                    }
                }
            }
        }
    }

    // MARK: - モンスター挙動管理
    private func startMonsterMovement() {
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            let top = safeAreaTop + 70
            let x = CGFloat.random(in: 40...(screenSize.width - 40))
            let y = CGFloat.random(in: max(top, 40)...(screenSize.height - 40))
            withAnimation(.linear(duration: 0.5)) {
                spawnPosition = CGPoint(x: x, y: y)
            }
        }
    }

    private func stopMonsterMovement() {
        moveTimer?.invalidate()
        moveTimer = nil
    }

    private func scheduleMonsterTimeout() {
        monsterTimeoutTask?.cancel()
        let task = DispatchWorkItem {
            if spawnedMonster != nil {
                withAnimation { spawnedMonster = nil }
                message = "シオノコに逃げられた…"
                stopMonsterMovement()
            }
        }
        monsterTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: task)
    }

    private func triggerTapParticles() {
        tapParticlesID = UUID()
        showTapParticles = true
        let currentID = tapParticlesID
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if tapParticlesID == currentID {
                showTapParticles = false
            }
        }
    }
}
