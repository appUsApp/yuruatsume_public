import SwiftUI
import SwiftData
import AVFoundation

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex: Int = 0
    @State private var positions: [CGPoint] = []
    @State private var wiggleAngles: [Double] = []
    @State private var audioPlayer: AVAudioPlayer? = nil
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager
    @AppStorage("GalleryView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    @Query private var items: [GameItem]
    @Query private var monsters: [MonsterRecord]
    @Query private var ownedMaps: [OwnedMapItem]

    private var pages: [String] {
        var result = baseGalleryPages
        let ownedSet = Set(ownedMaps.map { $0.name })
        for item in sampleMapItems {
            if ownedSet.contains(item.name) {
                result.append(contentsOf: ["\(item.name)g1", "\(item.name)g2"])
            }
        }
        return result
    }


    private let iconSize: CGFloat = 40

    private func imageName(for code: String) -> String {
        if code.hasPrefix("i") {
            return code
        } else if code.hasPrefix("c") {
            return code
        }
        return code
    }

    private func isObtained(_ code: String) -> Bool {
        if code.hasPrefix("i"), let id = Int(code.dropFirst()) {
            return items.first(where: { $0.itemId == id })?.discovered ?? false
        } else if code.hasPrefix("c"), let id = Int(code.dropFirst()) {
            return monsters.first(where: { $0.monsterId == id })?.hasPage ?? false
        }
        return false
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
    
    private func playFinishSound() {
        guard let path = Bundle.main.path(forResource: "finish", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        playFinishSound()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                Spacer()

                ZStack {
                    let icons = galleryPageContents[pages[pageIndex]] ?? []
                    let obtainedCount = icons.filter { isObtained($0) }.count
                    let bgSuffix = "\(galleryPercentage(for: obtainedCount))%"
                    Image(pages[pageIndex] + "_" + bgSuffix)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .id(pageIndex)
                        .transition(.opacity)
                        .overlay {
                            GeometryReader { geo in
                                ForEach(Array(icons.enumerated()), id: \.offset) { index, code in
                                    if positions.indices.contains(index) {
                                        let obtained = isObtained(code)
                                        Image(imageName(for: code))
                                            .resizable()
                                            .frame(width: iconSize, height: iconSize)
                                            .colorMultiply(obtained ? .white : .black)
                                            .opacity(obtained ? 1 : 0.5)
                                            .rotationEffect(.degrees(wiggleAngles.indices.contains(index) ? wiggleAngles[index] : 0))
                                            .position(positions[index])
                                            .onTapGesture {
                                                guard obtained else { return }
                                                if wiggleAngles.indices.contains(index) {
                                                    withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                                                        wiggleAngles[index] = 6
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                        wiggleAngles[index] = 0
                                                    }
                                                }
                                            }
                                    }
                                }
                                Color.clear
                                    .onAppear {
                                        positions = generatePositions(in: geo.size, count: icons.count)
                                        wiggleAngles = Array(repeating: 0, count: icons.count)
                                    }
                                    .onChange(of: pageIndex) {
                                        positions = generatePositions(in: geo.size, count: icons.count)
                                        wiggleAngles = Array(repeating: 0, count: icons.count)
                                    }
                            }
                        }
                        .animation(.easeInOut(duration: 0.4), value: pageIndex)
                }

                HStack(spacing: 24) {
                    Button(action: {
                        if pageIndex > 0 {
                            withAnimation(.easeInOut(duration: 0.4)) { pageIndex -= 1 }
                            playPageMoveSound()
                        }
                    }) {
                        Text("前へ")
                            .foregroundColor(.white)
                    }
                    .disabled(pageIndex == 0)

                    Text("\(pageIndex + 1) / \(pages.count)")
                        .foregroundColor(.white)

                    Button(action: {
                        if pageIndex < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.4)) { pageIndex += 1 }
                            playPageMoveSound()
                        }
                    }) {
                        Text("次へ")
                            .foregroundColor(.white)
                    }
                    .disabled(pageIndex == pages.count - 1)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal)

            if showGuide {
                FirstVisitGuideView(
                    title: "ギャラリー",
                    messages: [
                        "集めたアイテムやシオノコを確認できるギャラリー！",
                        "各ページはアイテムやシオノコを集めるたび完成に近づくよ。",
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
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    if horizontalAmount < 0 {
                        if pageIndex < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.4)) { pageIndex += 1 }
                            playPageMoveSound()
                        }
                    } else if horizontalAmount > 0 {
                        if pageIndex > 0 {
                            withAnimation(.easeInOut(duration: 0.4)) { pageIndex -= 1 }
                            playPageMoveSound()
                        }
                    }
                }
        )
        .onAppear {
            galleryBadge.resetBadge()
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation {
                        showGuide = true
                    }
                }
            }
        }
    }
}

#Preview {
    GalleryView()
}
