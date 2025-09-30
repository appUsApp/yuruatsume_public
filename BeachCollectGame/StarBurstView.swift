import SwiftUI

struct StarBurstView: View {
    @State private var burst = false
    private let starCount = 8
    private let radius: CGFloat = 120
    var color: Color = .yellow

    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { i in
                let angle = Double(i) / Double(starCount) * 2 * Double.pi
                Image(systemName: "star.fill")
                    .foregroundColor(color)
                    .scaleEffect(burst ? 1.2 : 0.1)
                    .opacity(burst ? 0 : 1)
                    .offset(x: burst ? CGFloat(cos(angle) * Double(radius)) : 0,
                            y: burst ? CGFloat(sin(angle) * Double(radius)) : 0)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                burst = true
            }
        }
    }
}

#Preview {
    StarBurstView()
}
