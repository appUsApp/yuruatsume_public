import SwiftUI
import SwiftData
import Foundation
import Combine

struct HintStripView: View {
    enum Mode {
        case items(location: String)
        case stamina
    }

    private let mode: Mode
    @Binding var message: String
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @EnvironmentObject private var missionManager: MissionManager
    @Query private var allItems: [GameItem]
    @Query private var ownedMaps: [OwnedMapItem]
    @State private var selection: Int = 0
    @State private var bonusRefresh: Int = 0
    @ObservedObject private var staminaService: StaminaService
    @Binding private var popupMessage: String?
    @State private var isRefilling = false
    @State private var nowDate = Date()
    @State private var adErrorMessage: String?
    // ▼ リロール用広告のエラーメッセージ
    @State private var bonusAdErrorMessage: String?
    private var isPresentingBonusAdError: Binding<Bool> {
        Binding(get: { bonusAdErrorMessage != nil },
                set: { if !$0 { bonusAdErrorMessage = nil } })
    }

    private let staminaClock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private let hudWidth: CGFloat = 300
    private let iconSize: CGFloat = 40
    private let maxDisplay: Int = 5
    private let staminaIconSize: CGFloat = 28

    private var isPresentingAdError: Binding<Bool> {
        Binding(
            get: { adErrorMessage != nil },
            set: { if !$0 { adErrorMessage = nil } }
        )
    }

    init(appearLocation: String,
         message: Binding<String> = .constant(""),
         popupMessage: Binding<String?> = .constant(nil)) {
        self.mode = .items(location: appearLocation)
        _message = message
        _popupMessage = popupMessage
        _staminaService = ObservedObject(wrappedValue: .shared)
    }

    init(staminaService: StaminaService = .shared,
         popupMessage: Binding<String?> = .constant(nil)) {
        self.mode = .stamina
        _message = .constant("")
        _popupMessage = popupMessage
        _staminaService = ObservedObject(wrappedValue: staminaService)
    }

    private var filteredItems: [GameItem] {
        guard case let .items(location) = mode else { return [] }
        let timeKey = "\(timeManager.current)"
        return allItems.filter { item in
            item.count == 0 &&
            item.appearLocations.contains(location) &&
            ((location == "BeachScratch" || location == "FishAppear") ? item.appearTimes.contains(timeKey) : true)
        }
        .sorted {
            if $0.rarity == $1.rarity {
                return $0.itemId < $1.itemId
            }
            return $0.rarity < $1.rarity
        }
    }

    private var bonusItems: [GameItem] {
        guard case .items = mode else { return [] }
        _ = bonusRefresh
        return BonusItemManager.currentBonusItems(
            allItems: allItems,
            ownedMaps: ownedMaps,
            consumed: timeManager.consumedBonusItemIds
        )
    }

    private var canReroll: Bool {
        guard case .items = mode else { return false }
        _ = bonusRefresh
        return BonusItemManager.canReroll()
    }

    private var nextBonusSwitchText: String {
        guard case .items = mode else { return "" }
        let nextDate = BonusItemManager.nextSwitchDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: nextDate))に切替"
    }

    private func stripForItems(_ items: [GameItem]) -> some View {
        let extra = max(0, items.count - maxDisplay)
        let display = Array(items.prefix(maxDisplay))
        return HStack(spacing: 8) {
            ForEach(display, id: \.itemId) { item in
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .colorMultiply(.black)
            }
        }
        .frame(width: hudWidth, alignment: .leading)
        .overlay(alignment: .trailing) {
            if extra > 0 {
                Text("+\(extra)")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.trailing, 18)
            }
        }
    }

    private func stripForBonusItems(_ items: [GameItem]) -> some View {
        let extra = max(0, items.count - maxDisplay)
        let display = Array(items.prefix(maxDisplay))
        let nextText = nextBonusSwitchText
        return HStack(spacing: 8) {
            ForEach(display, id: \.itemId) { item in
                ZStack {
                    if let effect = effectName(for: item.rarity) {
                        Image(effect)
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .opacity(effectOpacity(for: item.rarity))
                    }
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .colorMultiply(.black)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                        .padding(1)
                        .background(Color.black.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .padding(1)
                }
                .onTapGesture {
                    message = hintText(for: item)
                }
            }
        }
        .frame(width: hudWidth, alignment: .leading)
        .overlay(alignment: .trailing) {
            HStack(spacing: 4) {
                if extra > 0 {
                    Text("+\(extra)")
                        .font(.caption2)
                        .padding(4)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Text(nextText)
                    .font(.caption2)
                    .padding(4)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.trailing, 8)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                Task {
                    do {
                        let ok = try await BonusRewardedAdManager.shared.present()
                        if ok {
                            _ = BonusItemManager.rerollBonusItems(
                                allItems: allItems,
                                ownedMaps: ownedMaps,
                                consumed: timeManager.consumedBonusItemIds
                            )
                            await MainActor.run {
                                bonusRefresh += 1
                                popupMessage = "たくさん遊んでくれてありがとう！！ボーナスアイテムが再度抽選されました！"
                            }
                        }
                    } catch {
                        await MainActor.run {
                            bonusAdErrorMessage =
                              (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .offset(x: 10, y: 12)
            }
            .disabled(!canReroll)
            .opacity(canReroll ? 1 : 0.3)
            .padding(4)
        }
        // 先読み＆エラー表示
        .onAppear { BonusRewardedAdManager.shared.preload() }
        .alert("お知らせ", isPresented: isPresentingBonusAdError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(bonusAdErrorMessage ?? "")
        })
    }

    private func timeText(for times: [String]) -> String {
        let order: [String: Int] = ["morning": 0, "day": 1, "evening": 2, "night": 3]
        let mapping: [String: String] = ["morning": "あさ", "day": "ひる", "evening": "夕方", "night": "よる"]
        let sorted = times.sorted { (order[$0] ?? 99) < (order[$1] ?? 99) }
        return sorted.compactMap { mapping[$0] }.joined(separator: "、")
    }

    private func hintText(for item: GameItem) -> String {
        let timeString = timeText(for: item.appearTimes)

        guard let loc = item.appearLocations.first else {
            return ""
        }

        switch loc {
        case "BeachScratch":
            return "見つけられる場所：浜辺\n出現時間：\(timeString)"
        case "FishAppear":
            return "見つけられる場所：海辺\n出現時間：\(timeString)"
        default:
            return "見つけられる場所：\(loc)"
        }
    }

    private func effectName(for rarity: Int) -> String? {
        switch rarity {
        case 2: return "flash_rare2"
        case 3: return "flash_rare4"
        case 4: return "flash_rare5"
        default: return "flash_rare1"
        }
    }

    private func effectOpacity(for rarity: Int) -> Double {
        switch rarity {
        case 1: return 0.3
        case 2: return 0.5
        case 3: return 0.8
        default: return 1.0
        }
    }

    private func staminaStrip(currentDate: Date) -> some View {
        let totalHearts = 4
        let filledHearts = max(0, min(staminaService.current, totalHearts))
        let text = staminaRefillText(referenceDate: currentDate)
        let isAtMax = staminaService.current >= staminaService.max
        return HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<totalHearts, id: \.self) { index in
                    Image(index < filledHearts ? "HeartIconTapped" : "HeartIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: staminaIconSize, height: staminaIconSize)
                }
            }
            Text(text)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer()
            Button {
                guard !isRefilling else { return }
                if isAtMax {
                    adErrorMessage = "いいねポイントは既に最大です！"
                    return
                }
                isRefilling = true
                Task {
                    do {
                        let rewarded = try await RewardedAdManager.shared.present()
                        if rewarded {
                            let result = try await staminaService.recoverOneFromAd()
                            if result.didRecover {
                                await MainActor.run {
                                    popupMessage = "みんなにいいねしてくれてありがとう！いいねポイントを+1獲得しました！"
                                }
                            } else {
                                await MainActor.run {
                                    adErrorMessage = "いいねポイントは既に最大です！"
                                }
                            }
                        }
                    } catch {
                        let message: String
                        if let localized = (error as? LocalizedError)?.errorDescription {
                            message = localized
                        } else {
                            message = error.localizedDescription
                        }
                        await MainActor.run {
                            adErrorMessage = message
                        }
                    }
                    await MainActor.run {
                        isRefilling = false
                        nowDate = Date()
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .padding(6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    .foregroundStyle(.white)
            }
            .disabled(isRefilling)
            .opacity(isRefilling ? 0.3 : (isAtMax ? 0.6 : 1))
        }
        .frame(width: hudWidth, alignment: .leading)
        .alert("お知らせ", isPresented: isPresentingAdError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(adErrorMessage ?? "")
        })
        .onAppear {
            RewardedAdManager.shared.preload()
        }
    }

    private func staminaRefillText(referenceDate: Date) -> String {
        let target = resolvedNextRefillDate(referenceDate: referenceDate)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        formatter.dateFormat = "H:mm"
        return "次回: \(formatter.string(from: target))に回復"
    }

    private func resolvedNextRefillDate(referenceDate: Date) -> Date {
        if let next = staminaService.nextRefillAt, next > referenceDate {
            return next
        }
        return defaultNextRefillDate(after: referenceDate)
    }

    private func defaultNextRefillDate(after referenceDate: Date) -> Date {
        let hours = [4, 10, 16, 22]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? calendar.timeZone
        let base = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        for hour in hours {
            var components = base
            components.hour = hour
            components.minute = 0
            components.second = 0
            if let candidate = calendar.date(from: components), candidate > referenceDate {
                return candidate
            }
        }
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate)) else {
            return referenceDate
        }
        var nextComponents = calendar.dateComponents([.year, .month, .day], from: startOfNextDay)
        nextComponents.hour = hours.first
        nextComponents.minute = 0
        nextComponents.second = 0
        return calendar.date(from: nextComponents) ?? referenceDate
    }

    @ViewBuilder
    private func itemsContent() -> some View {
        let items = filteredItems
        let bonuses = bonusItems
        if items.isEmpty && bonuses.isEmpty {
            EmptyView()
        } else if items.isEmpty {
            stripForBonusItems(bonuses)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "#86C3D1", alpha: 0.1))
                        )
                )                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 4)
        } else if bonuses.isEmpty {
            stripForItems(items)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "#86C3D1", alpha: 0.1))
                        )
                )                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 4)
        } else {
            TabView(selection: $selection) {
                stripForItems(items)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "#86C3D1", alpha: 0.1))
                            )
                    )                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 4)
                    .tag(0)
                stripForBonusItems(bonuses)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "#86C3D1", alpha: 0.1))
                            )
                    )                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 4)
                    .tag(1)
            }
            .frame(width: hudWidth, height: iconSize + 16)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .bottom) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(selection == 0 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(selection == 1 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
                .padding(.bottom, 4)
            }
            .overlay(alignment: .trailing) {
                if selection == 0 {
                    Image(systemName: "chevron.compact.right")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.trailing, 6)
                }
            }
            .overlay(alignment: .leading) {
                if selection == 1 {
                    Image(systemName: "chevron.compact.left")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.leading, 6)
                }
            }
        }
    }

    private func attachPopupListener<Content: View>(_ content: Content) -> some View {
        content
            .onChange(of: missionManager.popupWindowMessage) { message in
                guard let message else { return }
                popupMessage = message
                missionManager.popupWindowMessage = nil
            }
    }

    var body: some View {
        switch mode {
        case .stamina:
            attachPopupListener(
                staminaStrip(currentDate: nowDate)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "#86C3D1", alpha: 0.1))
                        )
                )                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 4)
                .onReceive(staminaClock) { date in
                    nowDate = date
                }
            )
        case .items:
            attachPopupListener(itemsContent())
        }
    }
}

#Preview {
    HintStripView(appearLocation: "BeachScratch", message: .constant(""))
        .environmentObject(TimeOfDayManager())
        .environmentObject(MissionManager())
}

