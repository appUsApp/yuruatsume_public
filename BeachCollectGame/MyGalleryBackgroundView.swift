import SwiftUI
import SwiftData

/// Displays the saved MyGallery layout as a full-screen background.
struct MyGalleryBackgroundView: View {
    @Environment(\.modelContext) private var context
    @Query private var configs: [GalleryConfig]

    @State private var background = "MyGalleryBack01"
    @State private var backgroundEffect = "MyGalleryBE01"
    @State private var galleryImage = "e01_0%"
    @State private var galleryEffect = "MyGalleryGE01"
    @State private var monsters: [String] = []
    @State private var items: [String] = []
    @State private var positions: [CGPoint] = []

    private let iconSize: CGFloat = 50

    private var icons: [String] { monsters + items }

    private func loadConfig() {
        if let cfg = configs.first {
            background = cfg.background
            backgroundEffect = cfg.backgroundEffect
            galleryImage = cfg.image
            galleryEffect = cfg.decoration
            monsters = cfg.monsters
            items = cfg.items
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
                Image(background)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Image(backgroundEffect)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

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
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear { loadConfig() }
    }
}

