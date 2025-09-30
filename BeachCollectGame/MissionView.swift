import SwiftUI
import AVFoundation

struct MissionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: MissionManager
    @Environment(\.modelContext) private var context

    enum Tab { case daily, total }
    @State private var tab: Tab = .daily
    @State private var audioPlayer: AVAudioPlayer? = nil
    @AppStorage("MissionView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false
    @State private var rewardMessage: String? = nil

    private func missionList(_ missions: [MissionManager.Mission]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(missions) { mission in
                ZStack {
                    Image("MissionChoice")
                        .resizable()
                        .scaledToFit()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mission.description)
                            Text("報酬: \(mission.reward)")
                                .font(.caption)
                            Text("\(min(mission.progress, mission.target))/\(mission.target)")
                                .font(.caption2)
                        }
                        .offset(x: 12, y: 6) 
                        Spacer()
                        if mission.id == "dailyWatchAd" {
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                Task {
                                    do {
                                        let ok = try await DailyMissionAdManager.shared.present()
                                        if ok {
                                            manager.claim(mission: mission, context: context) // ▶︎ 視聴成功で受け取り
                                            await MainActor.run {
                                                rewardMessage = "今日も遊びに来てくれてありがとう！！新しいシオノコと出会えますように！！泡沫結晶×5 を受け取ってください！"
                                            }
                                        }
                                    } catch {
                                        print("daily ad mission failed:", error.localizedDescription)
                                    }
                                }
                            }) {
                                Image("PlayButton")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .frame(width: 80)
                        } else {
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                manager.claim(mission: mission, context: context)
                            }) {
                                Image(mission.completed ? "MissionButton_a" : "MissionButton_d")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .disabled(!mission.completed)
                            .frame(width: 80)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func playPageMoveSound() {
        guard let path = Bundle.main.path(forResource: "pageMove", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    var body: some View {
        ZStack {
            Image("MissionBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                    }
                }
                .padding(.horizontal, 30)

                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) { tab = .daily }
                        playPageMoveSound()
                    }) {
                        Text("デイリー")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(tab == .daily ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) { tab = .total }
                        playPageMoveSound()
                    }) {
                        Text("通算")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(tab == .total ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                ScrollView {
                    if tab == .daily {
                        missionList(manager.sortedDailyMissions)
                            .id(Tab.daily)
                            .transition(.opacity)
                    } else {
                        missionList(manager.sortedTotalMissions)
                            .id(Tab.total)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.4), value: tab)
                .gesture(
                    DragGesture().onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) else { return }
                        if horizontal < -50 && tab == .daily {
                            withAnimation(.easeInOut(duration: 0.4)) { tab = .total }
                            playPageMoveSound()
                        } else if horizontal > 50 && tab == .total {
                            withAnimation(.easeInOut(duration: 0.4)) { tab = .daily }
                            playPageMoveSound()
                        }
                    }
                )
                Spacer()
            }
            .foregroundColor(.white)

            if showGuide {
                FirstVisitGuideView(
                    title: "ミッション",
                    messages: [
                        "ミッションを達成して報酬を受け取ろう！",
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
        .overlay {
            if let message = rewardMessage {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { rewardMessage = nil }
                    SimpleMessagePopupView(message: message, onClose: { rewardMessage = nil })
                }
                .zIndex(1)
            }
        }
    }
}

#Preview {
    MissionView()
        .environmentObject(MissionManager())
}
