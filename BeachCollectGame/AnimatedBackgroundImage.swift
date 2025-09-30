import SwiftUI

/// A view that smoothly cross-fades between images whenever the name changes.
/// Useful for backgrounds that swap based on time of day.
struct AnimatedBackgroundImage: View {
    /// The target image name to display.
    var imageName: String

    /// Currently displayed image.
    @State private var currentImage: String
    /// Previously displayed image used during the cross-fade.
    @State private var previousImage: String?
    /// Opacity for the current image. Animation drives this value from 0→1.
    @State private var opacity: Double = 1.0

    init(imageName: String) {
        self.imageName = imageName
        _currentImage = State(initialValue: imageName)
    }

    var body: some View {
        ZStack {
            if let prev = previousImage {
                Image(prev)
                    .resizable()
                    .scaledToFill()
                    .opacity(1 - opacity)
            }
            Image(currentImage)
                .resizable()
                .scaledToFill()
                .opacity(opacity)
        }
        .onChange(of: imageName) { oldName, newName in
            // 変化がない場合は何もしない
            guard oldName != newName else { return }
            previousImage = oldName
            currentImage  = newName
            opacity = 0
            withAnimation(.easeInOut(duration: 1.0)) {
                opacity = 1
            }
            // フェード完了後に前画像を破棄
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                previousImage = nil
            }
        }
    }
}

