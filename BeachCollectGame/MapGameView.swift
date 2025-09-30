import SwiftUI
import SwiftData
import AVFoundation

struct MapGameView: View {
    enum Screen { case scratch, gacha }

    let mapName: String
    var onClose: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var screen: Screen = .scratch
    @State private var showCollection = false
    @State private var showMission = false
    @State private var showShop = false
    @State private var showBag = false
    @State private var showMyGallery = false
    @State private var showGachaMonsters = false
    @State private var showGachaItems = false
    @AppStorage("MapGameView.hasSeenGuide") private var hasSeenGuide = false
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @Query(filter: #Predicate<GameItem> { $0.count > 0 }) private var ownedItems: [GameItem]
    @Query(filter: #Predicate<MonsterRecord> { $0.obtained }) private var ownedMonsters: [MonsterRecord]
    @State private var accessMessage = ""
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var popupMessage: String? = nil
    @State private var showGuide = false

    private var canAccessGallery: Bool {
        meetsGalleryAccessRequirement(items: ownedItems, monsters: ownedMonsters)
    }

    var body: some View {
        ZStack {
            Group {
                switch screen {
                case .scratch:
                    BeachScratchView(backgroundImageName: mapName, appearLocation: mapName)
                        .transition(.move(edge: .bottom))
                case .gacha:
                    GachaView { withAnimation { screen = .scratch } }
                        .transition(.move(edge: .trailing))
                }
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top) {
            if screen != .gacha {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        PlayerStatusView()
                        HintStripView(
                            appearLocation: mapName,
                            message: $accessMessage,
                            popupMessage: $popupMessage
                        )
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 20) {
                        GalleryNavigationButton {
                            showCollection = true
                        }
                        .environmentObject(galleryBadge)

                        GachaItemNavigationButton {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showGachaItems = true
                        }

                        GachaMonsterNavigationButton {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showGachaMonsters = true
                        }

                        Button {
                            withAnimation(.spring()) { screen = .gacha }
                        } label: {
                            Image("Gacham")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showMission = true
                        } label: {
                            Image("MissionIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .overlay(alignment: .topTrailing) {
                            if missionManager.hasUnclaimedRewards {
                                Circle()
                                    .fill(Color.indigo)
                                    .frame(width: 12, height: 12)
                                    .offset(x: -3, y: 2)
                            }
                        }

                        Button { showShop = true } label: {
                            Image("ShopIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            SoundEffect.play("open", player: &audioPlayer)
                            showBag = true
                        } label: {
                            Image("BagIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            if canAccessGallery {
                                showMyGallery = true
                            } else {
                                accessMessage = "「各レア度(1~4)のアイテム入手」＋「シオノコ4体とガチャで出会う」で開放されます"
                            }
                        } label: {
                            Image("e01_0%")
                                .resizable()
                                .scaledToFit()
                                .opacity(canAccessGallery ? 0.8 : 0.2)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if screen != .gacha {
                HStack {
                    Button(action: { dismiss() }) {
                        Image("蒼環のらせんm")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.8)
                            .padding(8)
                    }
                    .frame(width: 55, height: 55)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "#86C3D1", alpha: 0.1))
                            )
                    )                    .clipShape(Circle())
                    .shadow(radius: 2)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if screen != .gacha {
                ToolEffectTimerView()
                    .environmentObject(missionManager)
                    .padding([.trailing, .bottom], 8)
            }
        }
        .overlay {
            if let message = popupMessage {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { popupMessage = nil }
                    SimpleMessagePopupView(message: message) {
                        popupMessage = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if showGuide && screen != .gacha {
                FirstVisitGuideView(
                    title: "ビーチ探索",
                    messages: [
                        "左上のシルエットはまだ見つけていないアイテムが表示されている。",
                        "ボーナスアイテムはタップでヒント！泡沫結晶をゲットしよう！",
                        "ボーナスアイテムがなくなったら復活ボタンを押すか、復活を待とう！"
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
        .overlay {
            GeometryReader { geo in
                TimedMessageView(message: $accessMessage)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.28)
            }
        }
        .fullScreenCover(isPresented: $showCollection) { GalleryView() }
        .fullScreenCover(isPresented: $showMission) { MissionView() }
        .fullScreenCover(isPresented: $showShop) { ShopView() }
        .fullScreenCover(isPresented: $showBag) { BagView() }
        .fullScreenCover(isPresented: $showMyGallery) { MyGalleryView() }
        .sheet(isPresented: $showGachaMonsters) {
            GachaMonsterStatusView()
        }
        .sheet(isPresented: $showGachaItems) {
            GachaItemStatusView()
        }
        .onAppear {
            timeManager.playMapBGM(name: mapName)
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }
        .onDisappear {
            timeManager.stopOverrideBGM()
        }
    }
}

#Preview {
    MapGameView(mapName: "蒼環のらせん")
}
