//
//  ContentView.swift
//  BeachCollectGame
//
//  Created by のりやまのりを on 2025/04/08.
//
import SwiftUI
import AVFoundation
import SwiftData


struct BeachScratchView: View {
    var backgroundImageName: String? = nil
    var customBackground: AnyView? = nil
    var appearLocation: String
    /// Restrict monster appearance to these image names when provided
    var allowedMonsterIDs: [String]? = nil
    /// Restrict item appearance to these image names when provided
    var allowedItemIDs: [String]? = nil
    /// Enable OtherGallery-specific rules
    var isOtherGallery: Bool = false

    init(backgroundImageName: String? = nil,
         customBackground: AnyView? = nil,
         appearLocation: String = "BeachScratch",
         allowedMonsterIDs: [String]? = nil,
         allowedItemIDs: [String]? = nil,
         isOtherGallery: Bool = false) {
        self.backgroundImageName = backgroundImageName
        self.customBackground = customBackground
        self.appearLocation = appearLocation
        self.allowedMonsterIDs = allowedMonsterIDs
        self.allowedItemIDs = allowedItemIDs
        self.isOtherGallery = isOtherGallery
    }
    @Environment(\.modelContext) private var context
    @Query private var gameItems: [GameItem]
    @Query private var ownedMaps: [OwnedMapItem]
    @StateObject private var viewModel = ItemCollectionViewModel()
    @StateObject private var monsterVM = MonsterCollectionViewModel()
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager
    
    /// 1回のスクラッチ毎に抽選→当たりのときアイコンを表示
    @State private var foundItem: GameItem? = nil
    @State private var showFoundIcon: Bool = false
    @State private var foundIconPosition: CGPoint = .zero
    @State private var showScratchParticles: Bool = false
    @State private var scratchParticlesID = UUID()

    /// スクラッチで出現するモンスター
    @State private var monster: Monster? = nil
    @State private var monsterPosition: CGPoint = .zero
    
    /// メッセージ（例: 当たったアイテム名を表示する）
    @State private var message: String = ""
    
    /// ドラッグ中の前回位置
    @State private var lastDragPosition: CGPoint?
    
    /// 一回のスクラッチとみなす移動量(例: 30pt)
    let scratchDistanceThreshold: CGFloat = 30.0
    
    /// 効果音再生用
    @State private var audioPlayer: AVAudioPlayer? = nil

    // 画面サイズと安全領域を保持
    @State private var screenSize: CGSize = .zero
    @State private var safeAreaTop: CGFloat = 0

    // モンスター移動・タイムアウト管理
    @State private var moveTimer: Timer? = nil
    @State private var monsterTimeoutTask: DispatchWorkItem?

    private func randomMonster() -> Monster? {
        let allowedNames: [String]
        if let ids = allowedMonsterIDs {
            allowedNames = ids.map { String($0.dropFirst()) }
        } else {
            allowedNames = MonsterData.monsterIds(for: appearLocation)
        }
        let predicate: Predicate<MonsterRecord>
        if isOtherGallery {
            predicate = #Predicate { allowedNames.contains($0.name) }
        } else {
            predicate = #Predicate { allowedNames.contains($0.name) && $0.obtained }
        }
        let descriptor = FetchDescriptor<MonsterRecord>(predicate: predicate)
        if let records = try? context.fetch(descriptor), let record = records.randomElement() {
            let name = MonsterData.displayName(for: record.monsterId)
            return Monster(id: record.monsterId, name: name)
        }
        return nil
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景画像 (時間帯で切り替え)
                if let bg = customBackground {
                    bg
                        .frame(width: geo.size.width,
                               height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    AnimatedBackgroundImage(imageName: backgroundImageName ?? timeManager.beachImageName)
                        .frame(width: geo.size.width,
                               height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                }
            TimedMessageView(message: $message)
                .position(x: geo.size.width/2, y: geo.size.height * 0.28)
            
            // モンスターが出現している場合
            if let m = monster {
                MonsterAppearEffectView(monster: m) {
                    monsterTimeoutTask?.cancel()
                    stopMonsterMovement()
                    monster = nil
                    if isOtherGallery, let record = monsterVM.record(for: m), !record.obtained {
                        let count = monsterVM.incrementPreCount(for: m)
                        message = "\(m.name)と顔見知った。（\(count) / 50）"
                    } else {
                        let result = monsterVM.registerDefeat(of: m)
                        let count = result.0
                        missionManager.recordMonsterCatch(monster: m, isNew: result.1)
                        if result.1 {
                            galleryBadge.registerNewContent(imageName: m.imageName)
                        }
                        let target = missionManager.nextMonsterMissionTarget(count: count)
                        message = "\(m.name)となかよくなった。（\(count) / \(target)）"
                    }
                }
                .position(monsterPosition)
            }

            if showScratchParticles {
                ScratchParticleView()
                    .id(scratchParticlesID)
                    .position(foundIconPosition)
            }

            // 当たりが出ているときのみアイコンを表示し、
            // その上に透明ボタンを重ねてタップ判定とする
            if let item = foundItem, showFoundIcon {
                ZStack {
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 128, height: 128)

                    // アイコン上に透明ボタンを重ねる
                    Button(action: {
                        confirmFoundItem(item)
                    }) {
                        // ボタン自体は透明だがタップしやすいよう大きめの領域を設ける
                        Color.clear
                            .frame(width: 140, height: 140)
                    }
                    .contentShape(Rectangle())
                }
                .position(foundIconPosition)
            }

            if let got = viewModel.lastGottenItem, viewModel.lastGottenItemIsNew {
                ItemGetOverlayView(item: got, mapName: appearLocation) {
                    viewModel.lastGottenItem = nil
                }
                .zIndex(2)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        withAnimation { viewModel.lastGottenItem = nil }
                    }
                }
            }
        }
        .gesture(
            // onChangedで継続的に位置を見て、一定距離以上動いたら「1回抽選」する
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // すでに当たりが出て、まだボタン押していない場合はスキップ(当たりを保持)
                    if foundItem != nil || monster != nil {
                        return
                    }
                    
                    // 砂こすり中なので、前回位置からの移動距離を計測
                    if let lastPos = lastDragPosition {
                        let distance = hypot(value.location.x - lastPos.x, value.location.y - lastPos.y)
                        if distance >= scratchDistanceThreshold {
                            // 一回分のスクラッチとみなす → 抽選
                            handleScratch(at: value.location)
                            // 今回を新たな基準位置に更新
                            lastDragPosition = value.location
                        }
                    } else {
                        // 初回ドラッグ時はとりあえず位置を記録だけ
                        lastDragPosition = value.location
                    }
                }
                .onEnded { _ in
                    // 指を離したときに最後にドラッグ位置をクリア
                    lastDragPosition = nil
                }
        )
        .onAppear {
            screenSize = geo.size
            safeAreaTop = geo.safeAreaInsets.top

            // SwiftDataが空なら初期登録
            initializeItemsIfNeeded(context: context)
            initializeMonstersIfNeeded(context: context)
            viewModel.context = context
            monsterVM.context = context
        }
    }

    }

    
    // MARK: - スクラッチ動作での抽選処理
    private func handleScratch(at location: CGPoint) {
        foundIconPosition = location
        scratchParticlesID = UUID()
        showScratchParticles = true
        let currentID = scratchParticlesID
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if scratchParticlesID == currentID {
                showScratchParticles = false
            }
        }
        if rollMonsterAppears(), let newMonster = randomMonster() {
            monster = newMonster
            monsterPosition = location
            startMonsterMovement()
            scheduleMonsterTimeout()
            let rarity = MonsterData.rarity(for: "\(newMonster.id)")
            triggerHaptic(hapticLevelForDiscovery(rarity: rarity, isItem: false))
            return
        }

        let isFound = rollItemFound() // 5%で当たり
        if isFound {
            let rarity = rollRarity()
            if let item = pickRandomItem(rarity: rarity) {
                // 当たりアイテムをUIに反映
                foundItem = item
                showFoundIcon = true

                // サウンド & バイブ
                let bonuses = BonusItemManager.currentBonusItems(
                    allItems: gameItems,
                    ownedMaps: ownedMaps,
                    consumed: timeManager.consumedBonusItemIds
                )
                let isBonus = bonuses.contains { $0.itemId == item.itemId }
                playFoundSound(for: rarity, isBonus: isBonus)
                triggerHaptic(hapticLevelForDiscovery(rarity: rarity, isItem: true))
            }
        } else {
            // ハズレならメッセージ等は出さず、何もしない
        }
    }
    
    private func rollItemFound() -> Bool {
        let base = 3
        let multiplier = missionManager.isToolActive(.enmonite) ? 5 : 1
        let threshold = min(100, base * multiplier)
        return Int.random(in: 1...100) <= threshold
    }

    private func rollMonsterAppears() -> Bool {
        let base = 1
        let multiplier = missionManager.isToolActive(.horasyuugou) ? 10 : 1
        let threshold = min(1500, base * multiplier)
        return Int.random(in: 1...1500) <= threshold
    }

    private func rollRarity() -> Int {
        let r = Int.random(in: 1...100)
        if missionManager.isToolActive(.luckypearl) {
            switch r {
            case 1...80: return 2
            case 81...95: return 3
            default:      return 4
            }
        } else {
            switch r {
            case 1...80: return 1
            case 81...95: return 2
            case 96...99: return 3
            default:      return 4
            }
        }
    }
    
    /// レア度・場所・時間帯に合致するアイテムをランダムに取得
    private func pickRandomItem(rarity: Int) -> GameItem? {
        if isOtherGallery, let allowed = allowedItemIDs {
            let candidates = gameItems.filter { allowed.contains($0.imageName) && $0.rarity == rarity }
            let undiscovered = candidates.filter { !$0.discovered }
            return undiscovered.randomElement() ?? candidates.randomElement()
        }
        let timeKey = "\(timeManager.current)"
        let filtered = gameItems.filter { item in
            item.rarity == rarity &&
            item.appearLocations.contains(appearLocation) &&
            item.appearTimes.contains(timeKey)
        }

        let undiscovered = filtered.filter { !$0.discovered }
        if let u = undiscovered.randomElement() { return u }
        if let any = filtered.randomElement() { return any }

        let sameRarity = gameItems.filter {
            $0.rarity == rarity && $0.appearLocations.contains(appearLocation)
        }
        return sameRarity.randomElement()
    }
    
    /// 当たり確定ボタン押下時
    private func confirmFoundItem(_ item: GameItem) {
        if let updated = viewModel.acquire(item) {
            missionManager.recordItemGet(updated)
            if viewModel.lastGottenItemIsNew {
                galleryBadge.registerNewContent(imageName: updated.imageName)
            } else {
                let bonuses = BonusItemManager.currentBonusItems(
                    allItems: gameItems,
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
        
        // アイコンとボタンを消す
        foundItem = nil
        showFoundIcon = false
    }
    
    // MARK: - 効果音 & バイブ
    private func playFoundSound(for rarity: Int, isBonus: Bool) {
        let fileName: String
        if isBonus {
            fileName = "bonusItem.caf"
        } else {
            fileName = "sandyRarity\(rarity).caf"
        }
        if let path = Bundle.main.path(forResource: fileName, ofType: nil) {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("発見サウンド再生エラー: \(error)")
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
                monsterPosition = CGPoint(x: x, y: y)
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
            if monster != nil {
                withAnimation { monster = nil }
                message = "シオノコに逃げられた…"
                stopMonsterMovement()
            }
        }
        monsterTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: task)
    }
}







