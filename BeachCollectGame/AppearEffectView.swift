import SwiftUI

struct AppearEffectView: View {
    let imageName: String
    let size: CGFloat
    let initialScale: CGFloat
    let targetScale: CGFloat
    let bounceOffset: CGFloat
    let bounceDuration: Double
    let tapEnabledDelay: Double
    let fadeOutDelay: Double?
    var onTap: (() -> Void)?
    @Binding var fadeOut: Bool

    @State private var animate = false
    @State private var yOffset: CGFloat = 0
    @State private var canTap = false

    private let bounceAmount: CGFloat = 70

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: size, height: size)
            .opacity(fadeOut ? 0 : 1)
            .offset(y: yOffset)
            .scaleEffect(animate ? targetScale : initialScale)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    animate = true
                }
                withAnimation(.easeOut(duration: tapEnabledDelay)) {
                    yOffset = bounceOffset - bounceAmount / 2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + tapEnabledDelay) {
                    canTap = true
                    withAnimation(.easeInOut(duration: bounceDuration).repeatForever(autoreverses: true)) {
                        yOffset = bounceOffset + bounceAmount / 2
                    }
                }
                if let delay = fadeOutDelay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut) {
                            fadeOut = true
                        }
                    }
                }
            }
            .onTapGesture {
                if canTap {
                    onTap?()
                }
            }
    }
}

