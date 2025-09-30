import SwiftUI

struct MoneyGainView: View {
    let amount: Int
    @State private var offsetY: CGFloat = 10
    @State private var opacity: Double = 1

    var body: some View {
        Text("+\(amount)")
            .font(.body)
            .fontWeight(.bold)
            .foregroundColor(.green)
            .offset(x: 8, y: offsetY)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        offsetY = -20
                        opacity = 0
                    }
                }
            }
    }
}

#Preview {
    MoneyGainView(amount: 50)
}



