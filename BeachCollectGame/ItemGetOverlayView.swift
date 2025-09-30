import SwiftUI
import AVFoundation

struct ItemGetOverlayView: View {
    let item: GameItem
    /// マップ名が渡された場合はマップに応じた背景を表示し、
    /// それ以外では従来通り時間帯で切り替える
    var mapName: String? = nil
    var onClose: () -> Void = {}
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @State private var closeButtonEnabled = false
    @State private var audioPlayer: AVAudioPlayer? = nil

    private static let mapBackgrounds: [String: String] = [
        "ひかる石段": "ItemGet_morning",
        "波書のうまれる浜": "ItemGet_day",
        "うずしおオルガン": "ItemGet_evening",
        "さざめき浜": "ItemGet_evening",
        "ふたつ陽の海辺": "ItemGet_evening",
        "海の鳥居": "ItemGet_evening",
        "潮映回廊": "ItemGet_evening",
        "潮渡りの門": "ItemGet_evening",
        "泡天のはて": "ItemGet_evening",
        "夕映の貝望台": "ItemGet_evening",
        "くらげのそらまど": "ItemGet_night",
        "ねむれる書の根": "ItemGet_night",
        "貝火のどうくつ": "ItemGet_night",
        "星灯の読み処": "ItemGet_night",
        "蒼環のらせん": "ItemGet_night",
        "満月のテラス": "ItemGet_night",
        "満月の船橋": "ItemGet_night",
    ]

    private var backgroundName: String {
        if let mapName, let mapped = Self.mapBackgrounds[mapName] {
            return mapped
        }
        switch timeManager.current {
        case .morning: return "ItemGet_morning"
        case .day:     return "ItemGet_day"
        case .evening: return "ItemGet_evening"
        case .night:   return "ItemGet_night"
        }
    }

    private var effectName: String? {
        switch item.rarity {
        case 2: return "ItemGetEffect_2"
        case 3: return "ItemGetEffect_3"
        case 4: return "ItemGetEffect_4"
        default: return nil
        }
    }

    private var closeButtonColor: Color {
        switch timeManager.current {
        case .night:
            return .black
        default:
            return .white
        }
    }

    var body: some View {
        ZStack {
            // 背景部分をタップしたときも閉じられるように、全画面の透明レイヤーを配置する
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    if closeButtonEnabled {
                        onClose()
                    }
                }

            // オーバーレイ本体
            ZStack {
                Image(backgroundName)
                    .resizable()
                    .scaledToFit()

                if let effect = effectName {
                    Image(effect)
                        .resizable()
                        .scaledToFit()
                }

                VStack(spacing: 12) {

                    Image(item.imageName)
                        .resizable()
                        .frame(width: 120, height: 120)

                    Text(item.name)
                        .font(.title2)
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        ForEach(0..<item.rarity, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }

                    Text("GET!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)
                }
                .padding(24)
            }
            // オーバーレイ上でのタップが背景タップ判定にならないよう吸収
            .onTapGesture { }
            .offset(y: 30)
            .overlay(alignment: .bottom) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(closeButtonColor.opacity(0.1))
                        .foregroundColor(.white.opacity(0.5))
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .disabled(!closeButtonEnabled)
            }
            .cornerRadius(16)
        }
        .transition(.opacity)
        .onAppear {
            if (2...4).contains(item.rarity) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    closeButtonEnabled = true
                }
            } else {
                closeButtonEnabled = true
            }
        }
    }
}
