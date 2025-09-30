import SwiftUI
import SwiftData

struct MyGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @Query private var configs: [GalleryConfig]
    @Query(filter: #Predicate<GameItem> { $0.count > 0 }) private var ownedItems: [GameItem]
    @Query(filter: #Predicate<MonsterRecord> { $0.obtained }) private var ownedMonsters: [MonsterRecord]
    @State private var accessMessage = ""
    private var canAccessGallery: Bool {
        meetsGalleryAccessRequirement(items: ownedItems, monsters: ownedMonsters)
    }
    @State private var hideControls = false
    @State private var positions: [CGPoint] = []
    @AppStorage("MyGalleryView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    // MARK: - Gallery content states
    @State private var background = "MyGalleryBack01"
    @State private var backgroundEffect = "MyGalleryBE01"
    @State private var galleryImage = "e01_0%"
    @State private var galleryEffect = "MyGalleryGE01"
    @State private var monsters: [String] = []
    @State private var items: [String] = []
    @State private var bgmID: String = "BgmEvening"

    @State private var isEditing = false

    private var icons: [String] { monsters + items }
    private let iconSize: CGFloat = 50

    private func loadConfig() {
        if let cfg = configs.first {
            background = cfg.background
            backgroundEffect = cfg.backgroundEffect
            galleryImage = cfg.image
            galleryEffect = cfg.decoration
            monsters = cfg.monsters
            items = cfg.items
            bgmID = cfg.bgmID
        } else {
            let monsterNames = ownedMonsters.map { $0.imageName }.shuffled()
            monsters = Array(monsterNames.prefix(4))

            var selected: [String] = []
            for rarity in 1...4 {
                let candidates = ownedItems.filter { $0.rarity == rarity }
                if let choice = candidates.randomElement() {
                    selected.append(choice.imageName)
                }
            }
            items = selected

            let new = GalleryConfig(background: background,
                                   backgroundEffect: backgroundEffect,
                                   image: galleryImage,
                                   decoration: galleryEffect,
                                   monsters: monsters,
                                   items: items,
                                   bgmID: bgmID)
            context.insert(new)
            try? context.save()
        }
    }

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

    var body: some View {
        GeometryReader { proxy in
            let galleryWidth = min(proxy.size.width, proxy.size.height) * 0.85

            ZStack {
                Group {
                    if isEditing {
                        GalleryEditView(
                    currentBackground: background,
                    currentBackgroundEffect: backgroundEffect,
                    currentImage: galleryImage,
                    currentDecor: galleryEffect,
                    currentMonsters: monsters,
                    currentItems: items,
                    currentBgmID: bgmID,
                    onCancel: { isEditing = false },
                    onConfirm: { bg, be, img, deco, mons, its, bgm in
                        background = bg
                        backgroundEffect = be
                        galleryImage = img
                        galleryEffect = deco
                        monsters = mons
                        items = its
                        bgmID = bgm
                        positions = []
                        isEditing = false
                        timeManager.playMapBGM(name: bgm)
                    })
                } else {
                    ZStack {
                        Image(background)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()

                        Image(backgroundEffect)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()

                        VStack {
                            HStack {
                                if !hideControls {
                                    Button(action: {
                                        if canAccessGallery {
                                            isEditing = true
                                        } else {
                                            accessMessage = "「各レア度(1~4)のアイテム入手」＋「シオノコ4体とガチャで出会う」で開放されます"
                                        }
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .opacity(canAccessGallery ? 1 : 0.3)
                                    }
                                }
                                Spacer()
                                if !hideControls {
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 16)
                            Spacer()

                            ZStack {
                                Image(galleryImage)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(width: galleryWidth)
                                    .overlay {
                                        GeometryReader { geo in
                                            ForEach(Array(icons.enumerated()), id: \.offset) { index, name in
                                                if positions.indices.contains(index) {
                                                    Image(name)
                                                        .resizable()
                                                        .frame(width: iconSize, height: iconSize)
                                                        .position(positions[index])
                                                }
                                            }
                                            Color.clear
                                                .onAppear {
                                                    positions = generatePositions(in: geo.size, count: icons.count)
                                                }
                                                .onChange(of: icons.count) {
                                                    positions = generatePositions(in: geo.size, count: icons.count)
                                                }
                                        }
                                    }

                                Image(galleryEffect)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(width: galleryWidth)
                            }

                            Spacer()

                            HStack {
                                Spacer()
                                Button(action: { hideControls = true }) {
                                    Image(systemName: "square")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 16)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hideControls {
                            hideControls = false
                        }
                    }
                    .animation(.default, value: hideControls)
                }
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "マイギャラリー",
                    messages: [
                        "自分のギャラリーを飾ってみよう。",
                        "左上の編集ボタンから自由にカスタマイズできる！",
                        "ショップでギャラリーに飾れる素材を入手しよう",
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
            .overlay(alignment: .top) {
                TimedMessageView(message: $accessMessage)
                    .padding(.top, 60)
            }
            .onAppear {
                loadConfig()
                timeManager.playMapBGM(name: bgmID)
                if !hasSeenGuide {
                    DispatchQueue.main.async {
                        withAnimation { showGuide = true }
                    }
                }
            }
            .onDisappear {
                timeManager.stopOverrideBGM()
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

#Preview {
    MyGalleryView()
        .environmentObject(TimeOfDayManager())
}
