import SwiftUI

struct ProfileCircleAvatar: View {
    let imageID: String
    let effectID: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Image(imageID)
                .resizable()
                .scaledToFill()
            Image(effectID)
                .resizable()
                .scaledToFill()
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
        .shadow(radius: 2)
    }
}
