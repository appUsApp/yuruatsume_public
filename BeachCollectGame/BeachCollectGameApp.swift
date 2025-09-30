//
//  BeachCollectGameApp.swift
//  BeachCollectGame
//
//  Created by のりやまのりを on 2025/04/08.
//

import SwiftUI
import SwiftData
import AVFoundation
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleMobileAds
import Combine

/// 時間帯管理用オブジェクト
class TimeOfDayManager: ObservableObject {
    enum TimeOfDay: CaseIterable {
        case morning, day, evening, night
    }

    /// 現在の時間帯 (ゲーム開始時は昼)
    @Published private(set) var current: TimeOfDay = .day
    /// 現実時間に基づくボーナス用時間帯
    @Published private(set) var bonusTime: TimeOfDay = .day
    /// 取得済みボーナスアイテムID
    @Published private(set) var consumedBonusItemIds: Set<Int> = []

    private let consumedStorageKey = "BonusItemManager.consumed"

    /// 背景画像の候補（時間帯ごと）
    private let morningBackgrounds = [
        "bg1",
        "bg7",
        "bg14",
        "bg16",
        "bg30",
        "bg48",
    ]
    private let dayBackgrounds = [
        "BeachBackground1",
        "BeachBackground2",
        "BeachBackground3",
        "BeachBackground4",
        "BeachBackground5",
        "BeachBackground6",
    ]
    private let eveningBackgrounds = [
        "bg3",
        "bg9",
        "bg13",
        "bg20",
        "bg24",
        "bg26",
        "bg35",
        "bg38",
        "bg43",
        "bg47",
        "bg51",
    ]
    private let nightBackgrounds = [
        "bg4",
        "bg6",
        "bg11",
        "bg18",
        "bg21",
        "bg25",
        "bg28",
        "bg31",
        "bg40",
        "bg46",
        "bg49",
        "bg50",
    ]

    /// 各時間帯の現在のインデックス
    @Published private(set) var morningBackgroundIndex: Int = 0
    @Published private(set) var dayBackgroundIndex: Int = 0
    @Published private(set) var eveningBackgroundIndex: Int = 0
    @Published private(set) var nightBackgroundIndex: Int = 0

    private var timer: Timer?
    private var bgTimer: Timer?
    private var bonusTimer: Timer?
    private var bgmPlayer: AVAudioPlayer?
    /// ガチャBGMなど別のBGMを再生中は true
    var shouldOverrideBGM: Bool = false
    /// マップなどで再生する固有BGMの名前
    private var overrideBGMName: String?
    private var cancellables = Set<AnyCancellable>()

    /// ボーナスアイテム取得済みIDを登録
    func consumeBonus(itemId: Int) {
        consumedBonusItemIds.insert(itemId)
        saveConsumed()
    }

    private func currentSlotKey() -> String {
        BonusItemManager.slotKey()
    }

    private func saveConsumed() {
        let key = currentSlotKey()
        var storage = UserDefaults.standard.dictionary(forKey: consumedStorageKey) as? [String: [Int]] ?? [:]
        storage[key] = Array(consumedBonusItemIds)
        UserDefaults.standard.set(storage, forKey: consumedStorageKey)
    }

    private func loadConsumed() {
        let key = currentSlotKey()
        let storage = UserDefaults.standard.dictionary(forKey: consumedStorageKey) as? [String: [Int]]
        if let list = storage?[key] {
            consumedBonusItemIds = Set(list)
        } else {
            consumedBonusItemIds.removeAll()
        }
    }

    private func clearConsumed() {
        consumedBonusItemIds.removeAll()
        saveConsumed()
    }

    init() {
        startTimer()
        restartBackgroundTimer()
        startBonusTimer()
        applyAudioPreference()
        NotificationCenter.default.publisher(for: .audioSettingsDidChange)
            .sink { [weak self] _ in
                self?.applyAudioPreference()
            }
            .store(in: &cancellables)
    }

    deinit {
        timer?.invalidate()
        bgTimer?.invalidate()
        bonusTimer?.invalidate()
        cancellables.removeAll()
    }

    /// 次の時間帯へ遷移
    private func advance() {
        switch current {
        case .day:     current = .evening
        case .evening: current = .night
        case .night:   current = .morning
        case .morning: current = .day
        }
        restartBackgroundTimer()
        if !shouldOverrideBGM {
            applyAudioPreference()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.advance()
        }
    }

    private func startBonusTimer() {
        updateBonusTime()
        loadConsumed()
        scheduleNextBonusCheck()
    }

    private func scheduleNextBonusCheck() {
        bonusTimer?.invalidate()
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let nextHour: Int
        switch hour {
        case 0..<4:  nextHour = 4
        case 4..<10: nextHour = 10
        case 10..<16: nextHour = 16
        case 16..<22: nextHour = 22
        default:     nextHour = 24
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = nextHour % 24
        comps.minute = 0
        comps.second = 0
        var nextDate = calendar.date(from: comps)!
        if nextHour == 24 {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
        }
        let interval = nextDate.timeIntervalSince(now)
        bonusTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.updateBonusTime()
            self?.loadConsumed()
            self?.scheduleNextBonusCheck()
        }
    }

    private func updateBonusTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        let newTime: TimeOfDay
        switch hour {
        case 4..<10:  newTime = .morning
        case 10..<16: newTime = .day
        case 16..<22: newTime = .evening
        default:      newTime = .night
        }
        if newTime != bonusTime {
            bonusTime = newTime
            clearConsumed()
        }
    }

    /// 背景用タイマーを開始・再始動
    private func restartBackgroundTimer() {
        bgTimer?.invalidate()
        // 時間帯切り替え時は必ず先頭を表示
        switch current {
        case .morning:
            morningBackgroundIndex = 0
        case .day:
            dayBackgroundIndex = 0
        case .evening:
            eveningBackgroundIndex = 0
        case .night:
            nightBackgroundIndex = 0
        }
        bgTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.randomizeBackgroundIndex()
        }
    }

    private func randomizeBackgroundIndex() {
        switch current {
        case .morning:
            morningBackgroundIndex = Int.random(in: 0..<morningBackgrounds.count)
        case .day:
            dayBackgroundIndex = Int.random(in: 0..<dayBackgrounds.count)
        case .evening:
            eveningBackgroundIndex = Int.random(in: 0..<eveningBackgrounds.count)
        case .night:
            nightBackgroundIndex = Int.random(in: 0..<nightBackgrounds.count)
        }
    }

    /// 時間帯ごとのビーチ背景名
    var beachImageName: String {
        switch current {
        case .morning:
            return morningBackgrounds[morningBackgroundIndex]
        case .day:
            return dayBackgrounds[dayBackgroundIndex]
        case .evening:
            return eveningBackgrounds[eveningBackgroundIndex]
        case .night:
            return nightBackgrounds[nightBackgroundIndex]
        }
    }

    /// 時間帯ごとの海背景名
    var seaImageName: String {
        switch current {
        case .morning: return "SeaMorning"
        case .day:     return "SeaBackground"
        case .evening: return "SeaEvening"
        case .night:   return "SeaNight"
        }
    }

    private func applyAudioPreference() {
        guard AudioSettings.isAudioEnabled else {
            bgmPlayer?.stop()
            return
        }

        if shouldOverrideBGM, let name = overrideBGMName {
            playBGM(named: name)
        } else {
            playBGM(for: current)
        }
    }

    /// 指定した名前のBGMを再生
    private func playBGM(named name: String) {
        guard AudioSettings.isAudioEnabled else {
            bgmPlayer?.stop()
            return
        }
        guard let path = Bundle.main.path(forResource: name, ofType: "caf") else { return }
        let url = URL(fileURLWithPath: path)
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.play()
    }

    /// 時間帯に応じたBGMを再生
    private func playBGM(for time: TimeOfDay) {
        let name: String
        switch time {
        case .morning: name = "BgmMorning"
        case .day:     name = "BgmDay"
        case .evening: name = "BgmEvening"
        case .night:   name = "BgmNight"
        }
        playBGM(named: name)
    }

    /// 現在のBGMを停止
    func stopBGM() {
        bgmPlayer?.stop()
    }

    /// BGM を再開（マップBGMが設定されていればそれを再生）
    func resumeBGM() {
        shouldOverrideBGM = overrideBGMName != nil
        applyAudioPreference()
    }

    /// マップ固有のBGMを再生
    func playMapBGM(name: String) {
        overrideBGMName = name
        shouldOverrideBGM = true
        applyAudioPreference()
    }

    /// マップ固有のBGMを停止して時間帯BGMに戻す
    func stopOverrideBGM() {
        overrideBGMName = nil
        shouldOverrideBGM = false
        applyAudioPreference()
    }

    /// 時間帯を直接指定して変更
    func setTime(_ time: TimeOfDay) {
        current = time
        timer?.invalidate()
        startTimer()
        restartBackgroundTimer()
        if !shouldOverrideBGM {
            applyAudioPreference()
        }
    }
}

@main
struct BeachCollectGameApp: App {
    @StateObject private var timeManager = TimeOfDayManager()
    @StateObject private var gachaVM = GachaViewModel()
    @StateObject private var missionManager = MissionManager()
    @StateObject private var galleryBadge = GalleryBadgeManager()
    @StateObject private var firebaseManager = FirebaseManager()
    @StateObject private var authService = AuthService.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize the Google Mobile Ads SDK.
        MobileAds.shared.start()
        RewardedAdManager.shared.preload()
        BonusRewardedAdManager.shared.preload()
        DailyMissionAdManager.shared.preload()
    }


    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameItem.self,
            MonsterRecord.self,
            OwnedGalleryEffect.self,
            OwnedBackground.self,
            OwnedBackgroundEffect.self,
            OwnedMapItem.self,
            OwnedGalleryImage.self,
            OwnedBGM.self,
            GalleryConfig.self,
            MissionState.self,
            MissionMeta.self,
            ToolCountState.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            seedInitialGalleryImages(context: context)
            initializeMonstersIfNeeded(context: context)
            return container
        } catch {
            print("Could not load persistent ModelContainer: \(error). Using in-memory store.")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [memoryConfig])
            let context = ModelContext(container)
            seedInitialGalleryImages(context: context)
            initializeMonstersIfNeeded(context: context)
            return container
        }
    }()

    var body: some Scene {
        WindowGroup {

            MainGameView()
                .environmentObject(timeManager)
                .environmentObject(gachaVM)
                .environmentObject(missionManager)
                .environmentObject(galleryBadge)
                .environmentObject(firebaseManager)
                .environmentObject(authService)
                .environmentObject(networkMonitor)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .background else { return }
                    if let uid = authService.uid {
                        Task {
                            await CurrencyEarningsBuffer.shared.flushGoldNow(uid: uid)
                        }
                    }
                }

        }
        .modelContainer(sharedModelContainer)
    }
}

private func seedInitialGalleryImages(context: ModelContext) {
    for page in baseGalleryPages {
        let id = "\(page)_0%"
        let fetch = FetchDescriptor<OwnedGalleryImage>(predicate: #Predicate { $0.id == id })
        if ((try? context.fetch(fetch).isEmpty) ?? true) {
            context.insert(OwnedGalleryImage(id: id))
        }
    }
    try? context.save()
}
