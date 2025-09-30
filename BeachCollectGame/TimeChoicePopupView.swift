import SwiftUI
import AVFoundation

struct TimeChoicePopupView: View {
    var onSelect: (TimeOfDayManager.TimeOfDay) -> Void
    var onCancel: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }
    private let options: [TimeOfDayManager.TimeOfDay] = [.morning, .day, .evening, .night]

    private func imageName(for time: TimeOfDayManager.TimeOfDay) -> String {
        switch time {
        case .morning: return "Morning Button"
        case .day: return "Day Button"
        case .evening: return "Evening Button"
        case .night: return "Night Button"
        }
    }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("どの時に思いを馳せる？")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(options, id: \.self) { time in
                                Button {
                                    SoundEffect.play("Button", player: &audioPlayer)
                                    onSelect(time)
                                } label: {
                                    Image(imageName(for: time))
                                        .resizable()
                                        .renderingMode(.original)
                                        .scaledToFit()
                                        .frame(width: 120, height: 44)
                                }
                            }
                            Spacer()
                        }
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
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
        }
    }
}

#Preview {
    TimeChoicePopupView(onSelect: { _ in }, onCancel: {})
}

