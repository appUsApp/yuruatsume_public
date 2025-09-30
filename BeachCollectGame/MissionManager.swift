import Foundation
import SwiftUI
import SwiftData
import FirebaseAuth

/// 消費型ツールの所持数管理用キー
typealias ToolCounts = [ConsumableTool: Int]

@MainActor
class MissionManager: ObservableObject {
    /// 排他的に効果を発揮するツール一覧
    private let exclusiveTools: [ConsumableTool] = [.horasyuugou, .enmonite, .luckypearl]

    /// 現在発動中の排他ツール（無ければ nil）
    var currentExclusiveTool: ConsumableTool? {
        exclusiveTools.first(where: { isToolActive($0) })
    }
    enum MissionType { case daily, total }
    struct Mission: Identifiable {
        let id: String
        let type: MissionType
        var description: String
        var reward: String
        var target: Int
        var progress: Int = 0
        var received: Bool = false
        var stages: [Int] = []
        var stageIndex: Int = 0
        var descriptionTemplate: String? = nil
        var stageDescriptions: [String] = []
        var stageRewards: [String] = []

        var completed: Bool { progress >= target }

        init(id: String, type: MissionType, description: String, reward: String, target: Int,
             stages: [Int] = [], descriptionTemplate: String? = nil, stageDescriptions: [String] = [], stageRewards: [String] = []) {
            self.id = id
            self.type = type
            self.description = description
            self.reward = reward
            self.target = target
            self.stages = stages
            self.descriptionTemplate = descriptionTemplate
            self.stageDescriptions = stageDescriptions
            self.stageRewards = stageRewards
        }
    }

    @Published private(set) var dailyMissions: [Mission] = []
    @Published private(set) var totalMissions: [Mission] = []

    /// SwiftData context for persistence
    var context: ModelContext?

    private var galleryCounts: [String: Int] = [:]
    private var ownedMapNames: Set<String> = []

    private let stageValuesRare1: [Int] = [50, 100, 150, 200]
    private let stageValuesRare2: [Int] = [10, 20, 30, 40]
    private let stageValuesRare3: [Int] = [3, 6, 9, 12]
    private let stageValuesRare4: [Int] = [1, 2, 3, 4]
    private let stageValuesMonster: [Int] = [3, 15]

    private lazy var stageValuesByRarity: [Int: [Int]] = [
        1: stageValuesRare1,
        2: stageValuesRare2,
        3: stageValuesRare3,
        4: stageValuesRare4
    ]

    /// Next mission target for the given item count and rarity
    func nextItemMissionTarget(item: GameItem, count: Int) -> Int {
        let stages = stageValuesByRarity[item.rarity] ?? stageValuesRare4
        return stages.first { count <= $0 } ?? stages.last ?? count
    }

    /// Next mission target for monster capture count
    func nextMonsterMissionTarget(count: Int) -> Int {
        stageValuesMonster.first { count <= $0 } ?? stageValuesMonster.last ?? count
    }

    var sortedDailyMissions: [Mission] {
        sortMissions(dailyMissions)
    }

    var sortedTotalMissions: [Mission] {
        sortMissions(totalMissions)
    }

    /// True if any mission is completed and reward has not been claimed.
    var hasUnclaimedRewards: Bool {
        dailyMissions.contains(where: { $0.completed }) ||
        totalMissions.contains(where: { $0.completed })
    }

    /// Amount of money gained in the most recent transaction.
    @Published var lastMoneyGain: Int = 0

    /// ポップアップウィンドウで表示するメッセージ。
    @Published var popupWindowMessage: String? = nil

    /// 所持ツール数
    @Published var toolCounts: ToolCounts = [
        .horasyuugou: 1,
        .enmonite: 1,
        .luckypearl: 1,
        .tokinohotate: 1
    ]

    /// 発動中ツールの終了時刻
    @Published private var toolEffects: [ConsumableTool: Date] = [:]
    private let toolEffectKeyPrefix = "toolEffectEndAt_"
    /// タイマー更新用
    @Published private var effectTicker: Date = Date()
    private var effectTimer: Timer?

    /// Add money and record the gained amount for UI effects.
    /// Firestore書き込みはバッファ経由で間引く。
    func gainMoney(_ amount: Int, xp: Int = 0) {
        guard amount > 0 else { return }
        Task {
            await CurrencyEarningsBuffer.shared.earnGold(amount, xp: xp)
            if let uid = Auth.auth().currentUser?.uid {
                // 閾値に満たなければノーオペ、超えていれば一括反映
                await CurrencyEarningsBuffer.shared.flushGoldIfNeeded(uid: uid)
            }
            await MainActor.run { self.lastMoneyGain = amount }
        }
    }

    /// ボーナスミッション時の重複ゴールド付与と泡沫結晶の追加付与をまとめて処理。
    func grantBonusMissionGold(duplicateGold: Int, multiplier: Int) {
        guard duplicateGold > 0, multiplier > 0 else { return }
        gainMoney(duplicateGold * multiplier)
        guard multiplier > 1, let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await CurrencyService.shared.increment(.bubbleCrystal, by: 1, uid: uid) }
        let message = "ボーナスアイテムを見つけた！いつもより多いお金と泡沫結晶を手に入れた！"
        popupWindowMessage = message
    }

    /// ツールを1つ使用
    func useTool(_ tool: ConsumableTool) {
        guard let current = toolCounts[tool], current > 0 else { return }
        toolCounts[tool] = current - 1

        switch tool {
        case .horasyuugou, .enmonite, .luckypearl:
            // 排他対象ツールは同時に1つしか効果を発揮しない
            for t in exclusiveTools { setToolEffect(t, end: nil) }
            setToolEffect(tool, end: Date().addingTimeInterval(600))
        case .tokinohotate:
            break
        }

        saveState()
    }

    /// ツールを購入して所持数を更新（所持金はFirestoreで減算）
    func purchase(tool: ConsumableTool, quantity: Int) {
        let current = toolCounts[tool] ?? 0
        toolCounts[tool] = current + quantity
        saveState()
    }

    /// 指定ツールの残り秒数を返す（期限切れならnil）
    func remainingSeconds(for tool: ConsumableTool) -> Int? {
        guard let expiry = toolEffects[tool] else { return nil }
        let remain = Int(expiry.timeIntervalSinceNow)
        if remain > 0 { return remain }
        setToolEffect(tool, end: nil)
        return nil
    }

    /// 残り時間を mm:ss 形式で取得
    func remainingTimeString(for tool: ConsumableTool) -> String? {
        guard let sec = remainingSeconds(for: tool) else { return nil }
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }

    func isToolActive(_ tool: ConsumableTool) -> Bool {
        remainingSeconds(for: tool) != nil
    }

    private var lastLogin: Date?

    private func key(for tool: ConsumableTool) -> String {
        toolEffectKeyPrefix + tool.rawValue
    }

    private func setToolEffect(_ tool: ConsumableTool, end: Date?) {
        let defaults = UserDefaults.standard
        let key = key(for: tool)
        if let end {
            toolEffects[tool] = end
            defaults.set(end, forKey: key)
        } else {
            toolEffects.removeValue(forKey: tool)
            defaults.removeObject(forKey: key)
        }
    }

    private func loadToolEffectsFromDefaults() {
        let defaults = UserDefaults.standard
        let now = Date()
        for tool in ConsumableTool.allCases {
            let key = key(for: tool)
            if let end = defaults.object(forKey: key) as? Date, end > now {
                toolEffects[tool] = end
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    init() {
        resetDailyMissions()
        setupTotalMissions()
        loadToolEffectsFromDefaults()
        effectTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                           repeats: true) { [weak self] _ in
            guard let self else { return }
            // ここは @Sendable コンテキスト
            Task { @MainActor in
                self.effectTicker = Date()
            }
        }
    }

    deinit {
        effectTimer?.invalidate()
    }

    private func resetDailyMissions() {
        var loginMission = Mission(id: "dailyLogin", type: .daily, description: "ログインする", reward: "100G", target: 1)
        loginMission.progress = 1
        var adMission = Mission(id: "dailyWatchAd",
                                type: .daily,
                                description: "次の世界の実装のためにちょっと貢献してあげる(広告を1回視てあげる)",
                                reward: "泡沫結晶×5",
                                target: 1)
        adMission.progress = 1  // ← 常に“達成状態”で開始
        dailyMissions = [
            loginMission,
            Mission(id: "dailyItem3", type: .daily, description: "アイテムを3個集める", reward: "100G", target: 3),
            Mission(id: "dailyMonster1", type: .daily, description: "シオノコと1回遊ぶ", reward: "100G", target: 1),
            Mission(id: "dailyItem10", type: .daily, description: "アイテムを10個集める", reward: "泡沫結晶×1", target: 10),
            Mission(id: "dailyMonster5", type: .daily, description: "シオノコと5回遊ぶ", reward: "泡沫結晶×1", target: 5),
            adMission
        ]

        // Remove persisted daily mission states when resetting for a new day
        if let ctx = context {
            let fetch = FetchDescriptor<MissionState>(predicate: #Predicate { $0.type == "daily" })
            if let states = try? ctx.fetch(fetch) {
                for s in states { ctx.delete(s) }
                try? ctx.save()
            }
        }
    }

    private func addItemMissions(_ items: [(Int, String)], rarity: Int, stageValues: [Int]) {
        guard let baseCount = stageValues.first else { return }
        for (id, name) in items {
            totalMissions.append(
                Mission(
                    id: "rare\(rarity)_\(id)",
                    type: .total,
                    description: "「\(name)」を\(baseCount)個ゲットする",
                    reward: "泡沫結晶×3",
                    target: baseCount,
                    stages: stageValues,
                    descriptionTemplate: "「\(name)」を%ld個ゲットする"
                )
            )
        }
    }

    private func setupTotalMissions() {
        totalMissions = [
            Mission(id: "totalItem10", type: .total, description: "アイテムを10個集める", reward: "泡沫結晶×15", target: 10),
            Mission(id: "totalItem30", type: .total, description: "アイテムを30個集める", reward: "泡沫結晶×15", target: 30),
            Mission(id: "totalMonster5", type: .total, description: "シオノコと10回遊ぶ", reward: "泡沫結晶×15", target: 10),
            Mission(id: "totalRare4", type: .total, description: "レア度4のアイテムを1つゲットする", reward: "泡沫結晶×20", target: 1)
        ]

        // 歌う流木ミッション (モデル)
        let driftwood = Mission(
            id: "driftwood",
            type: .total,
            description: "「歌う流木」を50個ゲットする",
            reward: "泡沫結晶×3",
            target: stageValuesRare1.first ?? 50,
            stages: stageValuesRare1,
            descriptionTemplate: "「歌う流木」を%ld個ゲットする"
        )
        totalMissions.append(driftwood)

        // レア度1アイテムごとのミッション
        let rare1Items: [(Int, String)] = [
            (5, "ひょうたんクラゲの抜け殻"),
            (6, "不思議な石"),
            (8, "白い声貝"),
            (16, "ひび割れココナッツ"),
            (44, "潮文の土器片"),
            (45, "潮文の土器片"),
            (52, "ネジ石"),
            (53, "バツイシ"),
            (56, "音水イソギンチャク"),
            (62, "ホタテ"),
            (68, "泣き貝"),
            (69, "巻貝"),
            (108, "サンドル"),
            (114, "アオリリ"),
            (118, "サンゴブレス"),
            (123, "ヒラキブック"),
            (129, "スピラカラム"),
            (139, "ヴァイオスパイク"),
            (142, "スパイラジェム"),
            (148, "スミスハンマー"),
            (155, "マナリード"),
            (163, "ジェムドロップ"),
            (167, "ぬいぐるみ(みゃー)"),
            (170, "オアスポスト"),
            (176, "タイドスクロール"),
            (183, "アメクラ"),
            (189, "ミナトランタン"),
            (194, "ツキフネ"),
            (201, "スカーレットトーテム")
        ]
        addItemMissions(rare1Items, rarity: 1, stageValues: stageValuesRare1)

        // レア度2アイテムごとのミッション
        let rare2Items: [(Int, String)] = [
            (2, "さざめく瓶"),
            (7, "海賊のコマ"),
            (9, "潜みヒレ石"),
            (10, "あわふき石"),
            (12, "砂のまくら"),
            (17, "白いネジ"),
            (24, "貝殻風車"),
            (33, "捨てられたおもちゃ"),
            (35, "潮色の風鈴"),
            (36, "封印された貝"),
            (37, "朽ちた物見台"),
            (41, "メッセージボトル"),
            (46, "魚の飾り"),
            (47, "魚の飾り"),
            (49, "音叉貝"),
            (58, "異国の鐘"),
            (78, "誘い海標"),
            (79, "音響泡"),
            (81, "波の絵"),
            (84, "水供草"),
            (97, "音響結晶の欠片"),
            (98, "泡鈴結晶の欠片"),
            (102, "浮かぶ貝の封筒"),
            (103, "浮遊する水灯クラゲ"),
            (104, "メロガイ"),
            (107, "マキバナ"),
            (111, "コスモドーム"),
            (113, "ルナチャム"),
            (120, "ルミリング"),
            (121, "ユウハガキ"),
            (122, "ツタフダ"),
            (126, "ホタラン"),
            (128, "スプラロッド"),
            (132, "シーリボン"),
            (136, "サンドクリスタ"),
            (138, "ミズアカリ灯"),
            (140, "フロストフレイム"),
            (141, "フレアハート"),
            (147, "ブレイズボウル"),
            (149, "フレイムアンビル"),
            (152, "ムーンデューン"),
            (154, "アロマポット"),
            (160, "シェルスレート"),
            (162, "ティアボトル"),
            (164, "アストロロッド"),
            (169, "ウェーブスクロール"),
            (172, "エメラルドゲート"),
            (174, "メモリアアーチ"),
            (178, "フォーチュンオーブ"),
            (180, "サンドタブレット"),
            (182, "サンシェル"),
            (185, "メロパール"),
            (190, "ブラケラン"),
            (192, "サンドグラス"),
            (195, "ルナクロノ"),
            (196, "メロボート"),
            (202, "タイドゲート"),
            (203, "パールシェル")
        ]
        addItemMissions(rare2Items, rarity: 2, stageValues: stageValuesRare2)

        // レア度3アイテムごとのミッション
        let rare3Items: [(Int, String)] = [
            (1, "ひだまりのかい"),
            (11, "しんかいポストカード"),
            (15, "泡たべ石"),
            (18, "星あつめのウニ"),
            (20, "砂浜の錆びたコンパス"),
            (21, "ガラスのボトルアート"),
            (22, "漂流砂時計"),
            (23, "砂音の記憶瓶"),
            (26, "水晶の貝笛"),
            (27, "泡の記録石"),
            (28, "夜潮の貝灯"),
            (29, "海辺の封印缶"),
            (31, "砂の結晶レンズ"),
            (32, "しおだまりたま"),
            (34, "古の測量坑"),
            (42, "貝巻きランタン"),
            (43, "砂上の機械軸"),
            (48, "夕焼け砂の瓶詰め"),
            (50, "金属羽"),
            (51, "砂浜のリング"),
            (55, "貝食蓮"),
            (57, "ひかりシダ"),
            (59, "水流鐘"),
            (67, "墨泡の音響板"),
            (73, "潮流のガラス灯"),
            (74, "不気味な人魂"),
            (75, "通信歯車"),
            (80, "浮環"),
            (82, "渦音レコード"),
            (85, "泡花の花冠"),
            (86, "白花の花冠"),
            (88, "漂う白花"),
            (89, "見送りリボン"),
            (90, "浮遊光"),
            (91, "あわふくはね"),
            (92, "みずのはね"),
            (93, "あわふくまきはね"),
            (95, "あわ時計(白)"),
            (96, "あわ時計(青)"),
            (105, "プリズムシェル"),
            (106, "ウズオルガン"),
            (112, "ホシビン"),
            (115, "ウェイブムーン"),
            (117, "ホシフダ"),
            (119, "ヒカリツボ"),
            (124, "ルミグリモア"),
            (125, "ムーンビン"),
            (130, "ヒカリプレート"),
            (133, "ランクブック"),
            (135, "スプラッシュジェム"),
            (137, "シーゲート"),
            (143, "アクアスクリプト"),
            (145, "ミストトリイ"),
            (146, "アクアフレイム"),
            (151, "ウェーブポータ"),
            (153, "グリッターブック"),
            (156, "フローララック"),
            (158, "アクアオベリス"),
            (161, "スイールシェル"),
            (165, "ぬいぐるみ(にゃー)"),
            (166, "ぬいぐるみ(んにゃー)"),
            (173, "サンドスピン"),
            (175, "サンセットベル"),
            (179, "ライトパイロン"),
            (181, "マリンフラスク"),
            (184, "モコスタ"),
            (187, "パステルドロップ"),
            (191, "ビーコンライト"),
            (193, "シーギフト"),
            (198, "レイヴンエンブレム"),
            (199, "アクアアンカー"),
            (200, "サンセットオーブ"),
            (205, "マリーンマップ")
        ]
        addItemMissions(rare3Items, rarity: 3, stageValues: stageValuesRare3)

        // レア度4アイテムごとのミッション
        let rare4Items: [(Int, String)] = [
            (3, "虹色の羽"),
            (13, "記憶の景色泡"),
            (14, "月のぬけがら"),
            (19, "ガラスの望遠鏡"),
            (25, "潮流回転計"),
            (30, "古びた計測器"),
            (38, "月光の鏡板"),
            (39, "謎の機械殻(黒)"),
            (40, "謎の機械殻(赤)"),
            (54, "泡の石灯"),
            (60, "ガラス花"),
            (61, "音響結晶"),
            (63, "潮陽の記録機"),
            (64, "潮影の記録機"),
            (65, "陽潮の卵"),
            (66, "影潮の卵"),
            (70, "ウズノメ"),
            (71, "沈黙の影"),
            (72, "水鏡の輪"),
            (76, "沈星ヒトデ"),
            (77, "沈星ランタン"),
            (83, "流星"),
            (87, "夢の雫石"),
            (94, "双子泡"),
            (99, "記憶の雫"),
            (100, "波音の抱球"),
            (101, "海霧の蝶"),
            (109, "ウタオーブ"),
            (110, "ルミラダー"),
            (116, "サンセオーブ"),
            (127, "モジデューン"),
            (131, "モステア"),
            (134, "スタリーページ"),
            (144, "サンライズゲート"),
            (150, "ソルコア"),
            (157, "ブレッドロア"),
            (159, "サニースパイラ"),
            (168, "ぬいぐるみ(もこもこ)"),
            (171, "サニーディスク"),
            (177, "ウェーブコイン"),
            (186, "アクアゴブレット"),
            (188, "フウリンチャイム"),
            (197, "ムーンケルプ"),
            (204, "コンパスシェル")
        ]
        addItemMissions(rare4Items, rarity: 4, stageValues: stageValuesRare4)

        // モンスター個別獲得ミッション
        for name in MonsterData.all {
            let id = MonsterData.id(for: name)
            let disp = MonsterData.displayName(for: id)
            let descriptions = ["\(disp)と顔見知りになる。",
                               "\(disp)と友達になる。"]
            totalMissions.append(
                Mission(
                    id: "monster_\(id)",
                    type: .total,
                    description: descriptions[0],
                    reward: "泡沫結晶×3",
                    target: stageValuesMonster.first ?? 3,
                    stages: stageValuesMonster,
                    descriptionTemplate: nil,
                    stageDescriptions: descriptions
                )
            )
        }

        setupGalleryMissions()
    }

    private func setupGalleryMissions() {
        // Non-shop pages start at 20%
        for page in baseGalleryPages {
            galleryCounts[page] = 0
            let stages = [20, 50, 80, 100]
            let rewards = stages.map { "\(page)_\($0)%" }
            let desc = [
                "収集率が 20% 以上",
                "収集率が 50% 以上",
                "収集率が 80% 以上",
                "収集率が 100%"
            ]
            let mission = Mission(id: "gallery_\(page)", type: .total,
                                  description: desc[0], reward: rewards[0], target: stages[0],
                                  stages: stages, stageDescriptions: desc, stageRewards: rewards)
            totalMissions.append(mission)
        }

        // Shop maps include purchase stage
        for item in sampleMapItems {
            for suffix in ["g1", "g2"] {
                let page = "\(item.name)\(suffix)"
                galleryCounts[page] = 0
                let stages = [1, 20, 50, 80, 100]
                let rewards = [0, 20, 50, 80, 100].map { "\(page)_\($0)%" }
                let desc = [
                    "該当マップを Shop で購入済み",
                    "収集率が 20% 以上",
                    "収集率が 50% 以上",
                    "収集率が 80% 以上",
                    "収集率が 100%"
                ]
                let mission = Mission(id: "gallery_\(page)", type: .total,
                                      description: desc[0], reward: rewards[0], target: stages[0],
                                      stages: stages, stageDescriptions: desc, stageRewards: rewards)
                totalMissions.append(mission)
            }
        }
    }

    private func dailyMissionIndex(id: String) -> Int? {
        dailyMissions.firstIndex { $0.id == id }
    }

    private func totalMissionIndex(id: String) -> Int? {
        totalMissions.firstIndex { $0.id == id }
    }

    private func updateGalleryMission(for page: String) {
        guard let idx = totalMissionIndex(id: "gallery_\(page)") else { return }
        if totalMissions[idx].stages.first == 1 && totalMissions[idx].stageIndex == 0 {
            let base = page.replacingOccurrences(of: "g1", with: "").replacingOccurrences(of: "g2", with: "")
            totalMissions[idx].progress = ownedMapNames.contains(base) ? 1 : 0
        } else {
            let count = galleryCounts[page] ?? 0
            totalMissions[idx].progress = galleryPercentage(for: count)
        }
    }

    private func sortMissions(_ missions: [Mission]) -> [Mission] {
        missions.enumerated().sorted { lhs, rhs in
            let lClaimable = lhs.element.completed && !lhs.element.received
            let rClaimable = rhs.element.completed && !rhs.element.received
            if lClaimable == rClaimable {
                return lhs.offset < rhs.offset
            }
            return lClaimable && !rClaimable
        }.map { $0.element }
    }

    func recordLogin() {
        resetDailyIfNeeded()
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastLogin, Calendar.current.isDate(last, inSameDayAs: today) {
            return
        }
        lastLogin = today

        if let idx = dailyMissionIndex(id: "dailyLogin") {
            dailyMissions[idx].progress = 1
        }
        saveState()
    }

    func recordItemGet(_ item: GameItem) {
        if let idx = dailyMissionIndex(id: "dailyItem3") {
            dailyMissions[idx].progress += 1
        }
        if let idx = dailyMissionIndex(id: "dailyItem10") {
            dailyMissions[idx].progress += 1
        }
        if let idx = totalMissionIndex(id: "totalItem10") {
            totalMissions[idx].progress += 1
        }
        if let idx = totalMissionIndex(id: "totalItem30") {
            totalMissions[idx].progress += 1
        }
        if item.rarity == 4 {
            if let idx = totalMissionIndex(id: "totalRare4") {
                totalMissions[idx].progress = 1
            }
        }

        if let idx = totalMissionIndex(id: "driftwood"), item.name == "歌う流木" {
            totalMissions[idx].progress += 1
        }

        switch item.rarity {
        case 1:
            let missionId = "rare1_\(item.itemId)"
            if let idx = totalMissionIndex(id: missionId) {
                totalMissions[idx].progress += 1
            }
        case 2:
            let missionId = "rare2_\(item.itemId)"
            if let idx = totalMissionIndex(id: missionId) {
                totalMissions[idx].progress += 1
            }
        case 3:
            let missionId = "rare3_\(item.itemId)"
            if let idx = totalMissionIndex(id: missionId) {
                totalMissions[idx].progress += 1
            }
        case 4:
            let missionId = "rare4_\(item.itemId)"
            if let idx = totalMissionIndex(id: missionId) {
                totalMissions[idx].progress += 1
            }
        default:
            break
        }

        if item.count == 1 {
            let code = "i\(item.itemId)"
            for (page, icons) in galleryPageContents where icons.contains(code) {
                galleryCounts[page, default: 0] += 1
                updateGalleryMission(for: page)
            }
        }
        saveState()
    }

    func recordMonsterCatch(monster: Monster, isNew: Bool) {
        if let idx = dailyMissionIndex(id: "dailyMonster1") {
            dailyMissions[idx].progress += 1
        }
        if let idx = dailyMissionIndex(id: "dailyMonster5") {
            dailyMissions[idx].progress += 1
        }
        if let idx = totalMissionIndex(id: "totalMonster5") {
            totalMissions[idx].progress += 1
        }
        let missionId = "monster_\(monster.id)"
        if let idx = totalMissionIndex(id: missionId) {
            totalMissions[idx].progress += 1
        }

        if isNew {
            let code = "c\(monster.id)"
            for (page, icons) in galleryPageContents where icons.contains(code) {
                galleryCounts[page, default: 0] += 1
                updateGalleryMission(for: page)
            }
        }
        saveState()
    }

    func recordMapPurchase(_ name: String) {
        ownedMapNames.insert(name)
        updateGalleryMission(for: "\(name)g1")
        updateGalleryMission(for: "\(name)g2")
        saveState()
    }

    func claim(mission: Mission, context: ModelContext) {
        self.context = context
        var xpIncremented = false
        switch mission.reward {
        case let str where str.contains("泡沫結晶"):
            if let number = Int(str.replacingOccurrences(of: "泡沫結晶×", with: "")),
               let uid = Auth.auth().currentUser?.uid {
                xpIncremented = true
                Task { try? await CurrencyService.shared.increment(.bubbleCrystal, by: number, uid: uid, xp: 1) }
            }
        case let str where str.contains("G"):
            if let number = Int(str.replacingOccurrences(of: "G", with: "")) {
                xpIncremented = true
                gainMoney(number, xp: 1)
            }
        case let id where id.contains("%"):
            let fetch = FetchDescriptor<OwnedGalleryImage>(predicate: #Predicate { $0.id == id })
            if ((try? context.fetch(fetch).isEmpty) ?? true) {
                context.insert(OwnedGalleryImage(id: id))
                try? context.save()
            }
        default:
            break
        }
        if !xpIncremented, let uid = Auth.auth().currentUser?.uid {
            Task { try? await CurrencyService.shared.incrementXP(uid: uid) }
        }

        if mission.type == .daily {
            if let idx = dailyMissionIndex(id: mission.id) {
                // Persist claimed daily mission
                let missionId = mission.id
                let fetch = FetchDescriptor<MissionState>(predicate: #Predicate { $0.id == missionId })
                if let existing = try? context.fetch(fetch).first {
                    existing.progress = mission.target
                    existing.received = true
                    existing.stageIndex = mission.stageIndex
                } else {
                    let state = MissionState(id: mission.id, type: "daily",
                                             progress: mission.target, received: true,
                                             stageIndex: mission.stageIndex)
                    context.insert(state)
                }
                dailyMissions.remove(at: idx)
            }
        }
        if mission.type == .total, let idx = totalMissionIndex(id: mission.id) {
            if !totalMissions[idx].stages.isEmpty &&
                totalMissions[idx].stageIndex < totalMissions[idx].stages.count - 1 {
                totalMissions[idx].stageIndex += 1
                let nextTarget = totalMissions[idx].stages[totalMissions[idx].stageIndex]
                totalMissions[idx].target = nextTarget
                if totalMissions[idx].stageDescriptions.indices.contains(totalMissions[idx].stageIndex) {
                    totalMissions[idx].description = totalMissions[idx].stageDescriptions[totalMissions[idx].stageIndex]
                } else if let tmpl = totalMissions[idx].descriptionTemplate {
                    totalMissions[idx].description = String(format: tmpl, nextTarget)
                }
                if totalMissions[idx].stageRewards.indices.contains(totalMissions[idx].stageIndex) {
                    totalMissions[idx].reward = totalMissions[idx].stageRewards[totalMissions[idx].stageIndex]
                }
                totalMissions[idx].received = false
                if mission.id.hasPrefix("gallery_") {
                    let page = mission.id.replacingOccurrences(of: "gallery_", with: "")
                    updateGalleryMission(for: page)
                }
            } else {
                let missionId = mission.id
                let fetch = FetchDescriptor<MissionState>(predicate: #Predicate { $0.id == missionId })
                if let existing = try? context.fetch(fetch).first {
                    existing.progress = mission.target
                    existing.received = true
                    existing.stageIndex = mission.stageIndex
                } else {
                    let state = MissionState(id: mission.id, type: "total",
                                             progress: mission.target, received: true,
                                             stageIndex: mission.stageIndex)
                    context.insert(state)
                }
                totalMissions.remove(at: idx)
            }
        }
        saveState(context: context)
    }

    /// Persist current mission state and meta information
    private func saveState(context: ModelContext) {
        // Existing states keyed by mission ID
        let fetch = FetchDescriptor<MissionState>()
        var existing: [String: MissionState] = [:]
        if let states = try? context.fetch(fetch) {
            for s in states { existing[s.id] = s }
        }

        // Update or insert states for active missions
        for m in dailyMissions {
            let state = existing.removeValue(forKey: m.id) ?? MissionState(id: m.id, type: "daily")
            state.progress = m.progress
            state.received = m.received
            state.stageIndex = m.stageIndex
            if state.modelContext == nil { context.insert(state) }
        }
        for m in totalMissions {
            let state = existing.removeValue(forKey: m.id) ?? MissionState(id: m.id, type: "total")
            state.progress = m.progress
            state.received = m.received
            state.stageIndex = m.stageIndex
            if state.modelContext == nil { context.insert(state) }
        }

        // Save login meta
        let metaFetch = FetchDescriptor<MissionMeta>()
        let meta = (try? context.fetch(metaFetch).first) ?? MissionMeta()
        meta.lastLogin = lastLogin
        if meta.modelContext == nil { context.insert(meta) }

        // Save tool counts
        let toolFetch = FetchDescriptor<ToolCountState>()
        var existingToolStates: [String: ToolCountState] = [:]
        if let toolStates = try? context.fetch(toolFetch) {
            for s in toolStates { existingToolStates[s.tool] = s }
        }
        for (tool, count) in toolCounts {
            let key = tool.rawValue
            let state = existingToolStates.removeValue(forKey: key) ?? ToolCountState(tool: key)
            state.count = count
            if state.modelContext == nil { context.insert(state) }
        }
        // Remove any leftover tool states
        for s in existingToolStates.values { context.delete(s) }

        try? context.save()
    }

    /// Convenience wrapper using stored context
    private func saveState() {
        if let ctx = context { saveState(context: ctx) }
    }

    /// Load persisted mission state at startup
    func loadState(context: ModelContext) {
        self.context = context
        if let states = try? context.fetch(FetchDescriptor<MissionState>()) {
            for state in states {
                switch state.type {
                case "daily":
                    if let idx = dailyMissionIndex(id: state.id) {
                        dailyMissions[idx].progress = state.progress
                        dailyMissions[idx].received = state.received
                        dailyMissions[idx].stageIndex = state.stageIndex
                        if state.received { dailyMissions.remove(at: idx) }
                    }
                case "total":
                    if let idx = totalMissionIndex(id: state.id) {
                        if state.received {
                            totalMissions.remove(at: idx)
                        } else {
                            totalMissions[idx].progress = state.progress
                            totalMissions[idx].stageIndex = state.stageIndex
                            totalMissions[idx].received = state.received
                            if totalMissions[idx].stageIndex > 0 {
                                let target = totalMissions[idx].stages[totalMissions[idx].stageIndex]
                                totalMissions[idx].target = target
                                if totalMissions[idx].stageDescriptions.indices.contains(totalMissions[idx].stageIndex) {
                                    totalMissions[idx].description = totalMissions[idx].stageDescriptions[totalMissions[idx].stageIndex]
                                } else if let tmpl = totalMissions[idx].descriptionTemplate {
                                    totalMissions[idx].description = String(format: tmpl, target)
                                }
                                if totalMissions[idx].stageRewards.indices.contains(totalMissions[idx].stageIndex) {
                                    totalMissions[idx].reward = totalMissions[idx].stageRewards[totalMissions[idx].stageIndex]
                                }
                            }
                        }
                    }
                default:
                    break
                }
            }
        }

        if let meta = try? context.fetch(FetchDescriptor<MissionMeta>()).first {
            lastLogin = meta.lastLogin
        }

        if let toolStates = try? context.fetch(FetchDescriptor<ToolCountState>()) {
            for state in toolStates {
                if let tool = ConsumableTool(rawValue: state.tool) {
                    toolCounts[tool] = state.count
                }
            }
        }
    }

    /// アカウント削除後にミッション関連の状態を初期化する
    func resetForAccountDeletion() {
        galleryCounts.removeAll()
        ownedMapNames.removeAll()
        lastLogin = nil
        lastMoneyGain = 0
        popupWindowMessage = nil
        toolCounts = [
            .horasyuugou: 1,
            .enmonite: 1,
            .luckypearl: 1,
            .tokinohotate: 1
        ]
        toolEffects.removeAll()
        resetDailyMissions()
        setupTotalMissions()
        saveState()
    }

    func resetDailyIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastLogin, !Calendar.current.isDate(last, inSameDayAs: today) {
            resetDailyMissions()
            lastLogin = today
        }
    }
}
