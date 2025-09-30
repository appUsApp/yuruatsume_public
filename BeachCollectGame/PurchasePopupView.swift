import SwiftUI
import AVFoundation

struct PurchasePopupView: View {
    let item: ShopItem
    let category: ShopCategory
    @Binding var quantity: Int
    var canBuy: Bool
    var onCancel: () -> Void
    var onConfirm: () -> Void

    private var totalPrice: Int {
        category == .tools ? item.price * quantity : item.price
    }
    
    private var popupWidth: CGFloat {
        min(UIScreen.main.bounds.width - 20, 420)
    }

    @State private var audioPlayer: AVAudioPlayer? = nil

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay(alignment: .top) {
                    VStack(spacing: 8) {
                        Text("\(item.name)を購入しますか？")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                        Text(category == .monster ? "\(totalPrice)★" : "\(totalPrice)G")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Image(item.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: category == .tools ? 80 : 120, height: category == .tools ? 80 : 120)
                        if category == .tools {
                            VStack(spacing: 4) {
                                Slider(value: Binding(
                                    get: { Double(quantity) },
                                    set: { quantity = Int($0) }
                                ), in: 1...10, step: 1)
                                .tint(.orange)
                                Text("数量：\(quantity)")
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onCancel()
                            }) {
                                Image("Cancel Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }

                            // ───── OK ─────
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                if canBuy { onConfirm() }
                            }) {
                                Image("OK Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }
                            .disabled(!canBuy)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .frame(height: 280)
                    .padding(.top, 24)
                }
        }
    }
}

#Preview {
    PurchasePopupView(item: sampleToolItems.first!, category: .tools, quantity: .constant(1), canBuy: true, onCancel: {}, onConfirm: {})
}
