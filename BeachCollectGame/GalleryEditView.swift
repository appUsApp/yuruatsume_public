import SwiftUI
import SwiftData
import AVFoundation

/// Editing interface for MyGalleryView.
struct GalleryEditView: View {
    /// Available editing categories.
    enum Category: String, CaseIterable, Identifiable {
        case background = "背景"
        case backgroundEffect = "エフェクト"
        case image = "絵画"
        case monster = "シオノコ"
        case item = "アイテム"
        case decoration = "飾り"
        case bgm = "BGM"

        var id: String { rawValue }
    }

    // Current selections passed from parent view
    let currentBackground: String
    let currentBackgroundEffect: String
    let currentImage: String
    let currentDecor: String
    let currentMonsters: [String]
    let currentItems: [String]
    let currentBgmID: String

    var onCancel: () -> Void
    var onConfirm: (String, String, String, String, [String], [String], String) -> Void

    // Temporary editing states
    @State private var background: String
    @State private var backgroundEffect: String
    @State private var galleryImage: String
    @State private var galleryEffect: String
    @State private var monsters: [String]
    @State private var items: [String]
    @State private var bgmID: String

    @State private var category: Category = .background
    @State private var positions: [CGPoint] = []
    @State private var message: String = ""

    private let iconSize: CGFloat = 40

    @Environment(\.modelContext) private var context
    @Query private var configs: [GalleryConfig]
    @Query private var allItems: [GameItem]
    @Query private var monsterRecords: [MonsterRecord]
    @Query private var ownedDecorations: [OwnedGalleryEffect]
    @Query private var ownedBackgrounds: [OwnedBackground]
    @Query private var ownedBackgroundEffects: [OwnedBackgroundEffect]
    @Query private var ownedImages: [OwnedGalleryImage]
    @Query private var ownedBgms: [OwnedBGM]
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @State private var audioPlayer: AVAudioPlayer? = nil

    init(currentBackground: String,
         currentBackgroundEffect: String,
         currentImage: String,
         currentDecor: String,
         currentMonsters: [String],
         currentItems: [String],
         currentBgmID: String,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (String, String, String, String, [String], [String], String) -> Void) {
        self.currentBackground = currentBackground
        self.currentBackgroundEffect = currentBackgroundEffect
        self.currentImage = currentImage
        self.currentDecor = currentDecor
        self.currentMonsters = currentMonsters
        self.currentItems = currentItems
        self.currentBgmID = currentBgmID
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        _background = State(initialValue: currentBackground)
        _backgroundEffect = State(initialValue: currentBackgroundEffect)
        _galleryImage = State(initialValue: currentImage)
        _galleryEffect = State(initialValue: currentDecor)
        _monsters = State(initialValue: currentMonsters)
        _items = State(initialValue: currentItems)
        _bgmID = State(initialValue: currentBgmID)
    }

    private var availableBackgrounds: [String] {
        let purchased = ownedBackgrounds.map { $0.id }.sorted()
        return ["MyGalleryBack01", "MyGalleryBack02"] + purchased
    }

    private var availableBackgroundEffects: [String] {
        var effects = ["MyGalleryBE01"]
        for owned in ownedBackgroundEffects.map({ $0.id }).sorted() where !effects.contains(owned) {
            effects.append(owned)
        }
        return effects
    }

    private var availableDecorations: [String] {
        var decorations = ["MyGalleryGE01"]
        for owned in ownedDecorations.map({ $0.id }).sorted() where !decorations.contains(owned) {
            decorations.append(owned)
        }
        return decorations
    }

    private var availableBgms: [String] {
        ["BgmMorning", "BgmDay", "BgmEvening", "BgmNight"] + ownedBgms.map { $0.id }
    }

    private let bgmIcons: [String: String] = [
        "BgmMorning": "m04_50%",
        "BgmDay": "d02_50%",
        "BgmEvening": "e04_50%",
        "BgmNight": "n06_50%"
    ]

    /// Owned monster image names.
    private var ownedMonsters: [String] {
        monsterRecords.filter { $0.obtained }.map { $0.imageName }
    }

    /// Owned item image names.
    private var ownedItems: [String] {
        allItems.filter { $0.count > 0 }.map { $0.imageName }
    }

    /// Lookup rarity for an item image name.
    private func rarity(of imageName: String) -> Int? {
        allItems.first { $0.imageName == imageName }?.rarity
    }

    /// Currently selected item rarities.
    private var selectedItemRarities: Set<Int> {
        Set(items.compactMap { rarity(of: $0) })
    }

    /// Owned gallery image names, choosing the highest progress per page.
    private var ownedGalleryImages: [String] {
        var best: [String: (id: String, progress: Int)] = [:]
        for image in ownedImages {
            let id = image.id
            guard let underscore = id.lastIndex(of: "_") else { continue }
            let page = String(id[..<underscore])
            let percentPart = id[id.index(after: underscore)...]
                .replacingOccurrences(of: "%", with: "")
            let progress = Int(percentPart) ?? 0
            if let existing = best[page] {
                if progress > existing.progress {
                    best[page] = (id, progress)
                }
            } else {
                best[page] = (id, progress)
            }
        }
        return best.values.map { $0.id }.sorted()
    }

    /// Generates non-overlapping random icon positions.
    private func generatePositions(in size: CGSize, count: Int) -> [CGPoint] {
        var result: [CGPoint] = []
        let radius = iconSize
        for _ in 0..<count {
            var candidate = CGPoint(x: .random(in: radius...size.width - radius),
                                   y: .random(in: radius...size.height - radius))
            var attempts = 0
            while attempts < 50 {
                var overlaps = false
                for p in result {
                    if hypot(p.x - candidate.x, p.y - candidate.y) < radius {
                        overlaps = true
                        break
                    }
                }
                if !overlaps { break }
                candidate = CGPoint(x: .random(in: radius...size.width - radius),
                                   y: .random(in: radius...size.height - radius))
                attempts += 1
            }
            result.append(candidate)
        }
        return result
    }

    private var allIcons: [String] { monsters + items }

    @ViewBuilder
    private func previewContent(maxWidth: CGFloat) -> some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()

            Image(backgroundEffect)
                .resizable()
                .scaledToFill()

            ZStack {
                Image(galleryImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: maxWidth)
                    .overlay { /* アイコン用 GeometryReader は丸ごと移動 */ }

                Image(galleryEffect)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: maxWidth)
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let previewWidth = min(proxy.size.width, proxy.size.height) * 0.85
            VStack(spacing: 0) {

            ZStack {
                previewContent(maxWidth: previewWidth)
            }
            .frame(height: proxy.size.height * 0.8)
            .clipped()
            .overlay(alignment: .top) {
                TimedMessageView(message: $message)
                    .padding(.top, 20)
            }

            .overlay(alignment: .topTrailing) {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                            .font(.title)
                    }
                    .padding(12)
                }

                .overlay(alignment: .bottomTrailing) {
                    Button("決定") {
                        SoundEffect.play("Button", player: &audioPlayer)
                        guard monsters.count == 4 else {
                            message = "シオノコは4体選択してください"
                            return
                        }
                        guard items.count == 4 else {
                            message = "アイテムは4つ選択してください"
                            return
                        }
                        saveConfig()
                        guard let uid = AuthService.shared.uid else {
                            onConfirm(background, backgroundEffect,
                                      galleryImage, galleryEffect,
                                      monsters, items, bgmID)
                            return
                        }
                        let cfg = GalleryConfigDoc(
                            id: uid,
                            userId: uid,
                            backgroundID: background,
                            backgroundEffectID: backgroundEffect,
                            galleryImageID: galleryImage,
                            monsterIDs: monsters,
                            itemIDs: items,
                            galleryEffectID: galleryEffect,
                            bgmID: bgmID
                        )
                        Task {
                            let path = FSPath.galleryConfig(uid)
                            do { try await FirestoreService.shared.upsert(path, cfg) }
                            catch { print("galleryConfigs upsert failed:", error) }
                            await PublicProfileSync.syncFrom(config: cfg, uid: uid)
                        }
                        onConfirm(background, backgroundEffect,
                                  galleryImage, galleryEffect,
                                  monsters, items, bgmID)
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(12)
                }

                // ---- 選択 UI ----
                Picker("カテゴリ", selection: $category) {
                    ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: category) {
                    SoundEffect.play("pageMove", player: &audioPlayer)
                    SoundEffect.play("Button", player: &audioPlayer)
                }

                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 8) {
                        ForEach(itemsForCurrentCategory(), id: \.self) { name in
                            let disabled = category == .item &&
                                !items.contains(name) &&
                                (rarity(of: name).map { selectedItemRarities.contains($0) } ?? false)
                            Image(category == .bgm ? (bgmIcons[name] ?? "\(name)m") : name)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .grayscale(disabled ? 1 : 0)
                                .opacity(disabled ? 0.3 : 1)
                                .onTapGesture {
                                    SoundEffect.play("Button", player: &audioPlayer)
                                    if category == .item && disabled {
                                        message = "同レアリティのアイテムが配置中です"
                                    } else {
                                        select(item: name)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected(name) ? .indigo : .clear, lineWidth: 3)
                                )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 160)
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private func isSelected(_ name: String) -> Bool {
        switch category {
        case .background: return background == name
        case .backgroundEffect: return backgroundEffect == name
        case .image: return galleryImage == name
        case .decoration: return galleryEffect == name
        case .monster: return monsters.contains(name)
        case .item: return items.contains(name)
        case .bgm: return bgmID == name
        }
    }

    private func itemsForCurrentCategory() -> [String] {
        switch category {
        case .background: return availableBackgrounds
        case .backgroundEffect: return availableBackgroundEffects
        case .image: return ownedGalleryImages
        case .monster: return ownedMonsters
        case .item: return ownedItems
        case .decoration: return availableDecorations
        case .bgm: return availableBgms
        }
    }

    private func select(item name: String) {
        switch category {
        case .background:
            background = name
        case .backgroundEffect:
            backgroundEffect = name
        case .image:
            galleryImage = name
        case .decoration:
            galleryEffect = name
        case .monster:
            if monsters.contains(name) {
                monsters.removeAll { $0 == name }
            } else {
                if monsters.count >= 4 { monsters.removeFirst() }
                monsters.append(name)
            }
        case .item:
            if items.contains(name) {
                items.removeAll { $0 == name }
            } else {
                if let r = rarity(of: name), selectedItemRarities.contains(r) {
                    message = "同レアリティのアイテムが配置中です"
                } else {
                    if items.count >= 4 { items.removeFirst() }
                    items.append(name)
                }
            }
        case .bgm:
            bgmID = name
            timeManager.playMapBGM(name: name)
        }
    }

    private func saveConfig() {
        if let existing = configs.first {
            existing.background = background
            existing.backgroundEffect = backgroundEffect
            existing.image = galleryImage
            existing.decoration = galleryEffect
            existing.monsters = monsters
            existing.items = items
            existing.bgmID = bgmID
        } else {
            let new = GalleryConfig(background: background,
                                   backgroundEffect: backgroundEffect,
                                   image: galleryImage,
                                   decoration: galleryEffect,
                                   monsters: monsters,
                                   items: items,
                                   bgmID: bgmID)
            context.insert(new)
        }
        try? context.save()
    }
}

#Preview {
    GalleryEditView(currentBackground: "MyGalleryBack01",
                    currentBackgroundEffect: "MyGalleryBE01",
                    currentImage: "e01_0%",
                    currentDecor: "MyGalleryGE01",
                    currentMonsters: ["c1"],
                    currentItems: ["i1"],
                    currentBgmID: "BgmEvening",
                    onCancel: {},
                    onConfirm: { _,_,_,_,_,_,_ in })
    .environmentObject(TimeOfDayManager())
}
