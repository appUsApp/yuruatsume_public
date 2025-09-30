import SwiftUI

struct GalleryNavigationButton: View {
    var action: () -> Void
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager

    var body: some View {
        ZStack {
            Button(action: action) {
                Image("GalleryIcon")
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
            )            .clipShape(Circle())
            .shadow(radius: 2)
            .overlay(alignment: .topTrailing) {
                if galleryBadge.hasNewContent {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 12, height: 12)
                        .offset(x: -3, y: 2)
                }
            }

            if let imageName = galleryBadge.animatingImageName {
                GalleryFlyInView(imageName: imageName) {
                    galleryBadge.animationCompleted()
                }
            }
        }
    }
}

private struct GalleryFlyInView: View {
    let imageName: String
    var onEnd: () -> Void
    @State private var offset: CGFloat = -60
    @State private var disappear = false

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 55, height: 55)
            .offset(x: offset)
            .opacity(disappear ? 0 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    offset = 0
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.4)) {
                    disappear = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onEnd()
                }
            }
    }
}

