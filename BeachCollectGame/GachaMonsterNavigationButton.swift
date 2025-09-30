import SwiftUI

struct GachaMonsterNavigationButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("c89")
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
        )
        .clipShape(Circle())
        .shadow(radius: 2)
    }
}
