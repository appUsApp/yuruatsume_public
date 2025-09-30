import SwiftUI
import SwiftData
import AVFoundation

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var listeners: FirestoreListeners
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var context
    @Query private var ownedEffects: [OwnedGalleryEffect]
    @Query private var ownedBackgroundEffects: [OwnedBackgroundEffect]
    @Query private var ownedBackgrounds: [OwnedBackground]
    @Query private var ownedBgms: [OwnedBGM]
    @Query private var ownedMaps: [OwnedMapItem]
    @Query(filter: #Predicate<MonsterRecord> { !$0.obtained }) private var unownedMonsters: [MonsterRecord]
    @State private var selectedItem: ShopItem? = nil
    @State private var selectedMonster: MonsterRecord? = nil
    @State private var purchaseQuantity: Int = 1
    @State private var category: ShopCategory = .tools
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var isLoading = false
    @State private var completionMessage: String? = nil
    @AppStorage("ShopView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false
    @State private var didEntrySync = false

    private let bubbleStarCostByRarity: [Int: Int] = [1: 20, 2: 50, 3: 100, 4: 200, 5: 500]

    private func playPageMoveSound() {
        guard let path = Bundle.main.path(forResource: "pageMove", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    private func playButtonSound() {
        SoundEffect.play("Button", player: &audioPlayer)
    }

    var body: some View {
        ZStack {
            Image(category.backgroundImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    PlayerStatusView()
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 30)

                ScrollView {
                    VStack(spacing: 12) {
                        let fp = listeners.user?.friendPoints ?? 0
                        switch category {
                        case .tools:
                            ForEach(sampleToolItems) { item in
                                ShopItemRow(item: item) {
                                    playButtonSound()
                                    selectedItem = item
                                    purchaseQuantity = 1
                                }
                            }
                        case .gallery:
                            let items = sampleGalleryItems.map { item -> (ShopItem, Bool, Int) in
                                let owned = ownedEffects.contains { $0.id == item.imageName }
                                let required = ShopRequirement.requiredFriendPoints(for: item.imageName, category: .gallery)
                                return (item, owned, required)
                            }
                            let available = items.filter { !$0.1 && fp >= $0.2 }.sorted { $0.2 < $1.2 }
                            let locked = items.filter { !$0.1 && fp < $0.2 }.sorted { $0.2 < $1.2 }
                            let purchased = items.filter { $0.1 }.sorted { $0.2 < $1.2 }
                            ForEach(available, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item) {
                                    playButtonSound()
                                    selectedItem = item
                                    purchaseQuantity = 1
                                }
                            }
                            ForEach(locked, id: \.0.id) { data in
                                let item = data.0
                                let required = data.2
                                ShopItemRow(item: item, disabled: true, requiredFP: required)
                            }
                            ForEach(purchased, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item, owned: true)
                            }
                        case .background:
                            let items = sampleBackgroundItems.map { item -> (ShopItem, Bool, Int) in
                                let owned = ownedBackgrounds.contains { $0.id == item.imageName }
                                let required = ShopRequirement.requiredFriendPoints(for: item.imageName, category: .background)
                                return (item, owned, required)
                            }
                            let available = items.filter { !$0.1 && fp >= $0.2 }.sorted { $0.2 < $1.2 }
                            let locked = items.filter { !$0.1 && fp < $0.2 }.sorted { $0.2 < $1.2 }
                            let purchased = items.filter { $0.1 }.sorted { $0.2 < $1.2 }
                            ForEach(available, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item) {
                                    playButtonSound()
                                    selectedItem = item
                                    purchaseQuantity = 1
                                }
                            }
                            ForEach(locked, id: \.0.id) { data in
                                let item = data.0
                                let required = data.2
                                ShopItemRow(item: item, disabled: true, requiredFP: required)
                            }
                            ForEach(purchased, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item, owned: true)
                            }
                        case .backgroundEffect:
                            let items = sampleBackgroundEffectItems.map { item -> (ShopItem, Bool, Int) in
                                let owned = ownedBackgroundEffects.contains { $0.id == item.imageName }
                                let required = ShopRequirement.requiredFriendPoints(for: item.imageName, category: .backgroundEffect)
                                return (item, owned, required)
                            }
                            let available = items.filter { !$0.1 && fp >= $0.2 }.sorted { $0.2 < $1.2 }
                            let locked = items.filter { !$0.1 && fp < $0.2 }.sorted { $0.2 < $1.2 }
                            let purchased = items.filter { $0.1 }.sorted { $0.2 < $1.2 }
                            ForEach(available, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item) {
                                    playButtonSound()
                                    selectedItem = item
                                    purchaseQuantity = 1
                                }
                            }
                            ForEach(locked, id: \.0.id) { data in
                                let item = data.0
                                let required = data.2
                                ShopItemRow(item: item, disabled: true, requiredFP: required)
                            }
                            ForEach(purchased, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item, owned: true)
                            }
                        case .map:
                            let items = sampleMapItems.map { item -> (ShopItem, Bool, Int) in
                                let owned = ownedMaps.contains { $0.name == item.name }
                                let required = ShopRequirement.requiredFriendPoints(for: item.name, category: .map)
                                return (item, owned, required)
                            }
                            let available = items.filter { !$0.1 && fp >= $0.2 }.sorted { $0.2 < $1.2 }
                            let locked = items.filter { !$0.1 && fp < $0.2 }.sorted { $0.2 < $1.2 }
                            let purchased = items.filter { $0.1 }.sorted { $0.2 < $1.2 }
                            ForEach(available, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item) {
                                    playButtonSound()
                                    selectedItem = item
                                    purchaseQuantity = 1
                                }
                            }
                            ForEach(locked, id: \.0.id) { data in
                                let item = data.0
                                let required = data.2
                                ShopItemRow(item: item, disabled: true, requiredFP: required)
                            }
                            ForEach(purchased, id: \.0.id) { data in
                                let item = data.0
                                ShopItemRow(item: item, owned: true)
                            }
                        case .monster:
                            // Sort by preCount (descending), rarity (ascending), then monster ID (ascending)
                            let sortedRecords = unownedMonsters.sorted { lhs, rhs in
                                if lhs.preCount != rhs.preCount {
                                    return lhs.preCount > rhs.preCount
                                }
                                if lhs.rarity != rhs.rarity {
                                    return lhs.rarity < rhs.rarity
                                }
                                return lhs.monsterId < rhs.monsterId
                            }
                            ForEach(sortedRecords) { record in
                                let basePrice = bubbleStarCostByRarity[record.rarity] ?? 0
                                let discount = record.preCount * 2
                                let price = max(0, basePrice - discount)
                                let displayName = MonsterData.displayName(for: record.monsterId)
                                let item = ShopItem(name: displayName.isEmpty ? record.name : displayName,
                                                    imageName: record.imageName,
                                                    price: price,
                                                    discount: discount)
                                ShopItemRow(item: item, currencyImageName: "bubbleStar") {                                    playButtonSound()
                                    selectedItem = item
                                    selectedMonster = record
                                    purchaseQuantity = 1
                                }
                            }
                        }
                    }
                    .id(category)
                    .transition(.opacity)
                    .padding(.horizontal)
                }
                .animation(.easeInOut(duration: 0.4), value: category)
                .gesture(
                    DragGesture().onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) else { return }
                        if horizontal < -50 {
                            if let index = ShopCategory.allCases.firstIndex(of: category),
                               index < ShopCategory.allCases.count - 1 {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    category = ShopCategory.allCases[index + 1]
                                }
                                playPageMoveSound()
                            }
                        } else if horizontal > 50 {
                            if let index = ShopCategory.allCases.firstIndex(of: category), index > 0 {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    category = ShopCategory.allCases[index - 1]
                                }
                                playPageMoveSound()
                            }
                        }
                    }
                )
                Spacer()
                
                Picker("カテゴリ", selection: $category) {
                    ForEach(ShopCategory.allCases) { cat in
                        Text(cat.label).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: category) {
                    playPageMoveSound()
                }
                .padding(18)
            }

            if let item = selectedItem {
                let cost = category == .tools ? item.price * purchaseQuantity : item.price
                let balance = category == .monster ? (listeners.user?.currencies.bubbleStar ?? 0) : (listeners.user?.currencies.gold ?? 0)
                PurchasePopupView(item: item,
                                  category: category,
                                  quantity: $purchaseQuantity,
                                  canBuy: balance >= cost,
                                  onCancel: {
                                      selectedItem = nil
                                      selectedMonster = nil
                                  },
                                  onConfirm: {
                                      Task { await confirmPurchase() }
                                  })
            }
            if let message = completionMessage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { completionMessage = nil }
                SimpleMessagePopupView(message: message, onClose: { completionMessage = nil })
            }
            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView().tint(.white)
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "ショップの使いかた",
                    messages: [
                        "ツールやマイギャラリー素材、新マップなどを購入できる!",
                        "スワイプで切り替えられる！",
                        "『いいね』ポイントでアイテムを解放しよう！",
                        "いいねポイントはマイギャラリー解放後に貯められる！"
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
        .onAppear {
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
            // ショップに入ったタイミングで未同期ゴールドをサーバーへ反映（1回だけ）
            if !didEntrySync, let uid = authService.uid {
                didEntrySync = true
                Task {
                    await CurrencyEarningsBuffer.shared.flushGoldNow(uid: uid)
                }
            }
        }
    }

    private func confirmPurchase() async {
        guard let item = selectedItem, let uid = authService.uid else { return }
        await MainActor.run { isLoading = true }
        let cost = category == .tools ? item.price * purchaseQuantity : item.price
        let asset: CurrencyService.Asset = category == .monster ? .bubbleStar : .gold

        let success = await CurrencyService.shared.purchase(asset, cost: cost, uid: uid)
        await MainActor.run { isLoading = false }
        guard success else { return }
        await MainActor.run {
            switch category {
            case .tools:
                if let tool = ConsumableTool.allCases.first(where: { $0.name == item.name }) {
                    missionManager.purchase(tool: tool, quantity: purchaseQuantity)
                }
            case .gallery:
                if !ownedEffects.contains(where: { $0.id == item.imageName }) {
                    let effect = OwnedGalleryEffect(id: item.imageName)
                    context.insert(effect)
                    try? context.save()
                }
            case .background:
                if !ownedBackgrounds.contains(where: { $0.id == item.imageName }) {
                    let bg = OwnedBackground(id: item.imageName)
                    context.insert(bg)
                    try? context.save()
                }
                if let bgm = backgroundBgmMapping[item.imageName],
                   !ownedBgms.contains(where: { $0.id == bgm }) {
                    let music = OwnedBGM(id: bgm)
                    context.insert(music)
                    try? context.save()
                }
            case .backgroundEffect:
                if !ownedBackgroundEffects.contains(where: { $0.id == item.imageName }) {
                    let bg = OwnedBackgroundEffect(id: item.imageName)
                    context.insert(bg)
                    try? context.save()
                }
            case .map:
                if !ownedMaps.contains(where: { $0.name == item.name }) {
                    let map = OwnedMapItem(name: item.name)
                    context.insert(map)
                    try? context.save()
                    missionManager.recordMapPurchase(item.name)
                }
            case .monster:
                if let record = selectedMonster {
                    record.obtained = true
                    try? context.save()
                }
            }
            selectedItem = nil
            selectedMonster = nil
            purchaseQuantity = 1
            completionMessage = "購入が完了しました。"
        }
    }
}

#Preview {
    ShopView()
}
