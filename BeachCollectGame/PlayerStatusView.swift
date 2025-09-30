import SwiftUI

struct PlayerStatusView: View {
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var listeners: FirestoreListeners
    @AppStorage("CurrencyEarningsBuffer.pendingGold") private var pendingGoldLocal: Int = 0
    @State private var showGain = false
    @State private var gainAmount: Int = 0

    private let hudWidth: CGFloat = 300
    private let hudHeight: CGFloat = 80
    private let nameWidth: CGFloat = 119
    private let moneyWidth: CGFloat = 85
    private let crystalWidth: CGFloat = 55
    private let starWidth: CGFloat = 45
    private let likeWidth: CGFloat = 55
    private let lvWidth: CGFloat = 45
    private let iconSize: CGFloat = 30

    var body: some View {
        let xp = listeners.user?.xp ?? 0
        let level = max(1, xp / 10 + 1)
        let baseGold = listeners.user?.currencies.gold ?? 0
        let displayGold = baseGold + pendingGoldLocal
        let bubbleStar = listeners.user?.currencies.bubbleStar ?? 0
        let friendPoints = listeners.user?.friendPoints ?? 0

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                
                Text(listeners.user?.username?.isEmpty == false ? (listeners.user?.username ?? "") : "プレイヤー")
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: nameWidth, alignment: .center)
                
                HStack(spacing: 4) {
                    Text("Lv.")
                        .fontWeight(.semibold)
                        .frame(width: iconSize, alignment: .trailing)
                    Text("\(level)")
                        .fontWeight(.semibold)
                        .frame(width: lvWidth, alignment: .trailing)
                }


                HStack(spacing: 4) {
                    Image("HeartIconTapped")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .layoutPriority(1)
                    Text("\(friendPoints)")
                        .monospacedDigit()
                        .frame(width: likeWidth, alignment: .trailing)

                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)


            HStack(spacing: 10) {

                HStack(spacing: 4) {
                    Image("Gold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                    Text("\(displayGold)")
                        .monospacedDigit()
                        .frame(width: moneyWidth, alignment: .trailing)
                }
                .overlay(alignment: .bottomTrailing) {
                    if showGain {
                        MoneyGainView(amount: gainAmount)
                            .transition(.opacity)
                            .onDisappear {
                                missionManager.lastMoneyGain = 0
                            }
                    }
                }

                HStack(spacing: 4) {
                    Image("bubbleStar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                    Text("\(bubbleStar)")
                        .monospacedDigit()
                        .frame(width: starWidth, alignment: .trailing)
                }
                
                HStack(spacing: 4) {
                    Image("泡沫結晶")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                    Text("\(listeners.user?.currencies.bubbleCrystal ?? 0)")
                        .monospacedDigit()
                        .frame(width: crystalWidth, alignment: .trailing)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading) 
        }
        .frame(width: hudWidth, height: hudHeight)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                )
        )        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 4)
        .onChange(of: missionManager.lastMoneyGain) { _, newValue in
            guard newValue > 0 else { return }
            gainAmount = newValue
            showGain = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation {
                    showGain = false
                }
            }
        }
    }
}
