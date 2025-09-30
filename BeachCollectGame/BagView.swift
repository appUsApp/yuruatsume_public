import SwiftUI
import AVFoundation

struct BagView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @State private var selectedTool: ConsumableTool? = nil
    @State private var showTimeChoice = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @AppStorage("BagView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    /// ツール使用確認メッセージ
    private var alertMessage: String {
        guard let selected = selectedTool else { return "" }
        let exclusive: [ConsumableTool] = [.horasyuugou, .enmonite, .luckypearl]
        if exclusive.contains(selected),
           let active = missionManager.currentExclusiveTool {
            return "\(active.name)を使用中です。\nこのツールを使用すると、\(active.name)の効果がなくなってしまいますが本当に使用しますか？"
        }
        return "このツールを使用しますか？"
    }

    var body: some View {
        ZStack {
            Image("bg5")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(ConsumableTool.allCases) { tool in
                            let count = missionManager.toolCounts[tool] ?? 0
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                selectedTool = tool
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(tool.imageName)
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tool.name)
                                            .font(.headline)
                                        Text(tool.description)
                                            .font(.caption)
                                    }
                                    .foregroundColor(count > 0 ? .white : .black.opacity(0.6))
                                    Spacer()
                                    Text("×\(count)")
                                        .fontWeight(.bold)
                                        .foregroundColor(count > 0 ? .white : .black.opacity(0.6))
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(count == 0)
                            .opacity(count > 0 ? 1 : 0.5)
                        }
                    }
                    .padding()
                }
                .safeAreaPadding(.horizontal)
                .padding(.horizontal)
            }
            // ここで「×」ボタンを safe‑area 右上へ差し込む
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    Button {
                        SoundEffect.play("close", player: &audioPlayer)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(.trailing, 30)
                    }
                    .contentShape(Rectangle())
                }
                .safeAreaPadding(.horizontal)
                .padding(.horizontal)
            }

            if let tool = selectedTool {
                Color.black.opacity(0.4).ignoresSafeArea()
                ConfirmPopupView(message: alertMessage,
                                 onCancel: { selectedTool = nil },
                                 onConfirm: {
                    selectedTool = nil
                    if tool == .tokinohotate {
                        showTimeChoice = true
                    } else {
                        missionManager.useTool(tool)
                    }
                })
                .zIndex(1)
            }

            if showTimeChoice {
                Color.black.opacity(0.4).ignoresSafeArea()
                TimeChoicePopupView(onSelect: { time in
                    missionManager.useTool(.tokinohotate)
                    timeManager.setTime(time)
                    showTimeChoice = false
                }, onCancel: {
                    showTimeChoice = false
                })
                .zIndex(1)
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "バッグの使いかた",
                    messages: [
                        "冒険の役に立つツールを使えるよ！",
                        "ツールはショップで買える！"
                    ]
                ) {
                    withAnimation {
                        hasSeenGuide = true
                        showGuide = false
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }
    }
}

#Preview {
    BagView()
}

