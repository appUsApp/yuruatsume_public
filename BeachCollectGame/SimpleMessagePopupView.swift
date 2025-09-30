import SwiftUI
import AVFoundation

struct SimpleMessagePopupView: View {
    var message: String
    var onClose: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack(spacing: 24) {
                        Spacer()
                        Text(message)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Spacer()
                        Button {
                            SoundEffect.play("Button", player: &audioPlayer)
                            onClose()
                        } label: {
                            Image("OK Button")
                                .resizable().renderingMode(.original)
                                .scaledToFit().frame(width: 120, height: 44)
                        }
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
        }
    }
}

#Preview {
    SimpleMessagePopupView(message: "テストメッセージ", onClose: {})
}

