import SwiftUI

struct ShockwaveView: View {
    @State private var expand = false
    var color: Color

    var body: some View {
        Circle()
            .stroke(color.opacity(0.8), lineWidth: 4)
            .scaleEffect(expand ? 3 : 0.1)
            .opacity(expand ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    expand = true
                }
            }
    }
}

#Preview {
    ShockwaveView(color: .blue)
}
