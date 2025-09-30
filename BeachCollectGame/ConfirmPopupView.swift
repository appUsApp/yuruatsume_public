import SwiftUI
import AVFoundation

struct ConfirmPopupView: View {
    var message: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onCancel()
                            } label: {
                                Image("Cancel Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onConfirm()
                            } label: {
                                Image("OK Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 120, height: 44)
                            }
                        }
                        .padding(.bottom, 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                }
        }
    }
}

#Preview {
    ConfirmPopupView(message: "テスト", onCancel: {}, onConfirm: {})
}

