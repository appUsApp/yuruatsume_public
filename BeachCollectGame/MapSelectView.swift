import SwiftUI
import SwiftData
import AVFoundation

// String を直接 Identifiable にしないよう、ラッパー型を用意
struct MapName: Identifiable, Hashable {
    let value: String
    var id: String { value }
}

struct MapSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var ownedMaps: [OwnedMapItem]
    @State private var selectedMap: MapName? = nil
    @State private var showBeachScratch = false
    @State private var showGalleryMap = false
    @State private var showOtherGalleryMap = false
    @Query(filter: #Predicate<GameItem> { $0.count > 0 }) private var ownedItems: [GameItem]
    @Query(filter: #Predicate<MonsterRecord> { $0.obtained }) private var ownedMonsters: [MonsterRecord]
    @State private var accessMessage = ""
    @State private var audioPlayer: AVAudioPlayer? = nil
    @AppStorage("MapSelectView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    private var canAccessGallery: Bool {
        meetsGalleryAccessRequirement(items: ownedItems, monsters: ownedMonsters)
    }

    var body: some View {
        ZStack {
            Image("bg12")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        SoundEffect.play("finish", player: &audioPlayer)
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                // マップ一覧
                ScrollView {
                    let columns = [GridItem(.adaptive(minimum: 80), spacing: 16)]
                    LazyVGrid(columns: columns, spacing: 16) {
                        // 常に表示される2枚
                        Button(action: {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            dismiss()
                        }) {
                            Image("moveSand")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            if canAccessGallery {
                                showGalleryMap = true
                            } else {
                                accessMessage = "「各レア度(1~4)のアイテム入手」＋「シオノコ4体とガチャで出会う」で開放されます"
                            }
                        }) {
                        Image("e01_0%")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .opacity(canAccessGallery ? 1 : 0.3)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            if canAccessGallery {
                                showOtherGalleryMap = true
                            } else {
                                accessMessage = "「各レア度(1~4)のアイテム入手」＋「シオノコ4体とガチャで出会う」で開放されます"
                            }
                        }) {
                        Image("e06_50%")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .opacity(canAccessGallery ? 1 : 0.3)
                        }
                        .buttonStyle(.plain)
                        // 購入マップ一覧
                        ForEach(sampleMapItems) { item in
                            let owned = ownedMaps.contains { $0.name == item.name }
                            Button(action: {
                                SoundEffect.play("pageMove", player: &audioPlayer)
                                if owned {
                                    selectedMap = MapName(value: item.name)
                                } else {
                                    accessMessage = "ショップでマップを購入すると開放されます"
                                }
                            }) {
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                            }
                            .buttonStyle(.plain)
                            .opacity(owned ? 1 : 0.4)
                        }
                    }
                    .padding()
                }
                Spacer()
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "マップ選択",
                    messages: [
                        "いろんな場所に遊びに行ける!",
                        "行けるマップは『ショップで購入したマップ』・『マイギャラリーマップ』・『ほかの人のギャラリーマップ』",
                        "",
                        "※マイギャラリーマップとほかの人のギャラリーマップにいけない場合は「各レア度(1~4)のアイテム入手」＋「シオノコ4体との出会い」で行けるようになるよ",
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
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }
        .fullScreenCover(isPresented: $showBeachScratch) {
            BeachScratchView()
        }
        .fullScreenCover(isPresented: $showGalleryMap) {
            MyGalleryMapGameView()
        }
        .fullScreenCover(isPresented: $showOtherGalleryMap) {
            OtherGalleryMapGameView()
        }
        .fullScreenCover(item: $selectedMap) { map in
            MapGameView(mapName: map.value) {
                dismiss()
            }
        }
    }
}
