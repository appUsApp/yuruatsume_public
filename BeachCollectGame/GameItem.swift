//
//  Item.swift
//  BeachCollectGame
//
//  Created by のりやまのりを on 2025/04/08.
//

import Foundation
import SwiftData

// MARK: - SwiftData Model
@Model class GameItem {
    var id: UUID
    /// Stable identifier used for icon lookup
    var itemId: Int
    var name: String
    var rarity: Int
    var appearLocations: [String]
    var appearTimes: [String]
    /// Total number of times this item has been obtained
    var count: Int
    var discovered: Bool

    /// Image asset name derived from the stable identifier
    var imageName: String { "i\(itemId)" }

    /// Gold awarded when this item is obtained again after discovery
    var duplicateGold: Int {
        switch rarity {
        case 1: return 10
        case 2: return 20
        case 3: return 50
        case 4: return 100
        default: return 10
        }
    }

    init(id: UUID = UUID(),
         itemId: Int,
         name: String,
         rarity: Int,
         appearLocations: [String],
         appearTimes: [String],
         count: Int = 0,
         discovered: Bool = false) {
        self.id = id
        self.itemId = itemId
        self.name = name
        self.rarity = rarity
        self.appearLocations = appearLocations
        self.appearTimes = appearTimes
        self.count = count
        self.discovered = discovered
    }
}

/// 初期アイテム登録用
func initializeItemsIfNeeded(context: ModelContext) {
    let existingCount = try? context.fetch(FetchDescriptor<GameItem>()).count
    if let count = existingCount, count > 0 {
        return
    }
    struct Seed {
        let id: Int
        let name: String
        let rarity: Int
        let appearLocations: [String]
        let appearTimes: [String]
    }

    let seeds: [Seed] = [
        Seed(id: 1, name: "ひだまりのかい", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["evening"]),
        Seed(id: 2, name: "さざめく瓶", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 3, name: "虹色の羽", rarity: 4,
             appearLocations: ["BeachScratch"],
             appearTimes: ["night"]),
        Seed(id: 4, name: "歌う流木", rarity: 1,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 5, name: "ひょうたんクラゲの抜け殻", rarity: 1,
             appearLocations: ["BeachScratch"],
             appearTimes: ["night"]),
        Seed(id: 6, name: "不思議な石", rarity: 1,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening"]),
        Seed(id: 7, name: "海賊のコマ", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 8, name: "白い声貝", rarity: 1,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 9, name: "潜みヒレ石", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day"]),
        Seed(id: 10, name: "あわふき石", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 11, name: "しんかいポストカード", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning"]),
        Seed(id: 12, name: "砂のまくら", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 13, name: "記憶の景色泡", rarity: 4,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning"]),
        Seed(id: 14, name: "月のぬけがら", rarity: 4,
             appearLocations: ["BeachScratch"],
             appearTimes: ["night"]),
        Seed(id: 15, name: "泡たべ石", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning"]),
        Seed(id: 16, name: "ひび割れココナッツ", rarity: 1,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening"]),
        Seed(id: 17, name: "白いネジ", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 18, name: "星あつめのウニ", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 19, name: "ガラスの望遠鏡", rarity: 4,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 20, name: "砂浜の錆びたコンパス", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["evening"]),
        Seed(id: 21, name: "ガラスのボトルアート", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 22, name: "漂流砂時計", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["evening"]),
        Seed(id: 23, name: "砂音の記憶瓶", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["evening"]),
        Seed(id: 24, name: "貝殻風車", rarity: 2,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 25, name: "潮流回転計", rarity: 4,
             appearLocations: ["BeachScratch"],
             appearTimes: ["evening"]),
        Seed(id: 26, name: "水晶の貝笛", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["morning"]),
        Seed(id: 27, name: "泡の記録石", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["day"]),
        Seed(id: 28, name: "夜潮の貝灯", rarity: 3,
             appearLocations: ["BeachScratch"],
             appearTimes: ["night"]),
        Seed(id: 29, name: "海辺の封印缶", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 30, name: "古びた計測器", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 31, name: "砂の結晶レンズ", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 32, name: "しおだまりたま", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 33, name: "捨てられたおもちゃ", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day"]),
        Seed(id: 34, name: "古の測量坑", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 35, name: "潮色の風鈴", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["evening", "night"]),
        Seed(id: 36, name: "封印された貝", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening"]),
        Seed(id: 37, name: "朽ちた物見台", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 38, name: "月光の鏡板", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 39, name: "謎の機械殻(黒)", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 40, name: "謎の機械殻(赤)", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 41, name: "メッセージボトル", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 42, name: "貝巻きランタン", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 43, name: "砂上の機械軸", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["day"]),
        Seed(id: 44, name: "潮文の土器片", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 45, name: "潮文の土器片", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 46, name: "魚の飾り", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 47, name: "魚の飾り", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 48, name: "夕焼け砂の瓶詰め", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 49, name: "音叉貝", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening"]),
        Seed(id: 50, name: "金属羽", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["day"]),
        Seed(id: 51, name: "砂浜のリング", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["day"]),
        Seed(id: 52, name: "ネジ石", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 53, name: "バツイシ", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 54, name: "泡の石灯", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 55, name: "貝食蓮", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["evening"]),
        Seed(id: 56, name: "音水イソギンチャク", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 57, name: "ひかりシダ", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 58, name: "異国の鐘", rarity: 2, appearLocations: ["BeachScratch"], appearTimes: ["evening", "night"]),
        Seed(id: 59, name: "水流鐘", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day"]),
        Seed(id: 60, name: "ガラス花", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 61, name: "音響結晶", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 62, name: "ホタテ", rarity: 1, appearLocations: ["BeachScratch"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 63, name: "潮陽の記録機", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["day"]),
        Seed(id: 64, name: "潮影の記録機", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 65, name: "陽潮の卵", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["day"]),
        Seed(id: 66, name: "影潮の卵", rarity: 4, appearLocations: ["BeachScratch"], appearTimes: ["night"]),
        Seed(id: 67, name: "墨泡の音響板", rarity: 3, appearLocations: ["BeachScratch"], appearTimes: ["morning"]),
        Seed(id: 68, name: "泣き貝", rarity: 1, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 69, name: "巻貝", rarity: 1, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening"]),
        Seed(id: 70, name: "ウズノメ", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["evening"]),
        Seed(id: 71, name: "沈黙の影", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 72, name: "水鏡の輪", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 73, name: "潮流のガラス灯", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 74, name: "不気味な人魂", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 75, name: "通信歯車", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["day"]),
        Seed(id: 76, name: "沈星ヒトデ", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["evening"]),
        Seed(id: 77, name: "沈星ランタン", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 78, name: "誘い海標", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 79, name: "音響泡", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 80, name: "浮環", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 81, name: "波の絵", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning", "evening"]),
        Seed(id: 82, name: "渦音レコード", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["evening"]),
        Seed(id: 83, name: "流星", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 84, name: "水供草", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 85, name: "泡花の花冠", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["day"]),
        Seed(id: 86, name: "白花の花冠", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["night"]),
        Seed(id: 87, name: "夢の雫石", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["evening", "night"]),
        Seed(id: 88, name: "漂う白花", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 89, name: "見送りリボン", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening"]),
        Seed(id: 90, name: "浮遊光", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "night"]),
        Seed(id: 91, name: "あわふくはね", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 92, name: "みずのはね", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 93, name: "あわふくまきはね", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "evening"]),
        Seed(id: 94, name: "双子泡", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 95, name: "あわ時計(白)", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["morning", "day"]),
        Seed(id: 96, name: "あわ時計(青)", rarity: 3, appearLocations: ["FishAppear"], appearTimes: ["evening", "night"]),
        Seed(id: 97, name: "音響結晶の欠片", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 98, name: "泡鈴結晶の欠片", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 99, name: "記憶の雫", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["evening"]),
        Seed(id: 100, name: "波音の抱球", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 101, name: "海霧の蝶", rarity: 4, appearLocations: ["FishAppear"], appearTimes: ["morning"]),
        Seed(id: 102, name: "浮かぶ貝の封筒", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["morning", "day", "evening"]),
        Seed(id: 103, name: "浮遊する水灯クラゲ", rarity: 2, appearLocations: ["FishAppear"], appearTimes: ["evening", "night"]),
        Seed(id: 104, name: "メロガイ", rarity: 2, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 105, name: "プリズムシェル", rarity: 3, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 106, name: "ウズオルガン", rarity: 3, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 107, name: "マキバナ", rarity: 2, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 108, name: "サンドル", rarity: 1, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 109, name: "ウタオーブ", rarity: 4, appearLocations: ["うずしおオルガン"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 110, name: "ルミラダー", rarity: 4, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 111, name: "コスモドーム", rarity: 2, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 112, name: "ホシビン", rarity: 3, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 113, name: "ルナチャム", rarity: 2, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 114, name: "アオリリ", rarity: 1, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 115, name: "ウェイブムーン", rarity: 3, appearLocations: ["くらげのそらまど"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 116, name: "サンセオーブ", rarity: 4, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 117, name: "ホシフダ", rarity: 3, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 118, name: "サンゴブレス", rarity: 1, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 119, name: "ヒカリツボ", rarity: 3, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 120, name: "ルミリング", rarity: 2, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 121, name: "ユウハガキ", rarity: 2, appearLocations: ["さざめき浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 122, name: "ツタフダ", rarity: 2, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 123, name: "ヒラキブック", rarity: 1, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 124, name: "ルミグリモア", rarity: 3, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 125, name: "ムーンビン", rarity: 3, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 126, name: "ホタラン", rarity: 2, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 127, name: "モジデューン", rarity: 4, appearLocations: ["ねむれる書の根"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 128, name: "スプラロッド", rarity: 2, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 129, name: "スピラカラム", rarity: 1, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 130, name: "ヒカリプレート", rarity: 3, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 131, name: "モステア", rarity: 4, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 132, name: "シーリボン", rarity: 2, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 133, name: "ランクブック", rarity: 3, appearLocations: ["ひかる石段"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 134, name: "スタリーページ", rarity: 4, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 135, name: "スプラッシュジェム", rarity: 3, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 136, name: "サンドクリスタ", rarity: 2, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 137, name: "シーゲート", rarity: 3, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 138, name: "ミズアカリ灯", rarity: 2, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 139, name: "ヴァイオスパイク", rarity: 1, appearLocations: ["ふたつ陽の海辺"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 140, name: "フロストフレイム", rarity: 2, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 141, name: "フレアハート", rarity: 2, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 142, name: "スパイラジェム", rarity: 1, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 143, name: "アクアスクリプト", rarity: 3, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 144, name: "サンライズゲート", rarity: 4, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 145, name: "ミストトリイ", rarity: 3, appearLocations: ["海の鳥居"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 146, name: "アクアフレイム", rarity: 3, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 147, name: "ブレイズボウル", rarity: 2, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 148, name: "スミスハンマー", rarity: 1, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 149, name: "フレイムアンビル", rarity: 2, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 150, name: "ソルコア", rarity: 4, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 151, name: "ウェーブポータ", rarity: 3, appearLocations: ["貝火のどうくつ"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 152, name: "ムーンデューン", rarity: 2, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 153, name: "グリッターブック", rarity: 3, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 154, name: "アロマポット", rarity: 2, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 155, name: "マナリード", rarity: 1, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 156, name: "フローララック", rarity: 3, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 157, name: "ブレッドロア", rarity: 4, appearLocations: ["星灯の読み処"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 158, name: "アクアオベリス", rarity: 3, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 159, name: "サニースパイラ", rarity: 4, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 160, name: "シェルスレート", rarity: 2, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 161, name: "スイールシェル", rarity: 3, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 162, name: "ティアボトル", rarity: 2, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 163, name: "ジェムドロップ", rarity: 1, appearLocations: ["蒼環のらせん"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 164, name: "アストロロッド", rarity: 2, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 165, name: "ぬいぐるみ(にゃー)", rarity: 3, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 166, name: "ぬいぐるみ(んにゃー)", rarity: 3, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 167, name: "ぬいぐるみ(みゃー)", rarity: 1, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 168, name: "ぬいぐるみ(もこもこ)", rarity: 4, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 169, name: "ウェーブスクロール", rarity: 2, appearLocations: ["潮映回廊"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 170, name: "オアスポスト", rarity: 1, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 171, name: "サニーディスク", rarity: 4, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 172, name: "エメラルドゲート", rarity: 2, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 173, name: "サンドスピン", rarity: 3, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 174, name: "メモリアアーチ", rarity: 2, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 175, name: "サンセットベル", rarity: 3, appearLocations: ["潮渡りの門"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 176, name: "タイドスクロール", rarity: 1, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 177, name: "ウェーブコイン", rarity: 4, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 178, name: "フォーチュンオーブ", rarity: 2, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 179, name: "ライトパイロン", rarity: 3, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 180, name: "サンドタブレット", rarity: 2, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 181, name: "マリンフラスク", rarity: 3, appearLocations: ["波書のうまれる浜"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 182, name: "サンシェル", rarity: 2, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 183, name: "アメクラ", rarity: 1, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 184, name: "モコスタ", rarity: 3, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 185, name: "メロパール", rarity: 2, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 186, name: "アクアゴブレット", rarity: 4, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 187, name: "パステルドロップ", rarity: 3, appearLocations: ["泡天のはて"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 188, name: "フウリンチャイム", rarity: 4, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 189, name: "ミナトランタン", rarity: 1, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 190, name: "ブラケラン", rarity: 2, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 191, name: "ビーコンライト", rarity: 3, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 192, name: "サンドグラス", rarity: 2, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 193, name: "シーギフト", rarity: 3, appearLocations: ["満月のテラス"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 194, name: "ツキフネ", rarity: 1, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 195, name: "ルナクロノ", rarity: 2, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 196, name: "メロボート", rarity: 2, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 197, name: "ムーンケルプ", rarity: 4, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 198, name: "レイヴンエンブレム", rarity: 3, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 199, name: "アクアアンカー", rarity: 3, appearLocations: ["満月の船橋"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 200, name: "サンセットオーブ", rarity: 3, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 201, name: "スカーレットトーテム", rarity: 1, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 202, name: "タイドゲート", rarity: 2, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 203, name: "パールシェル", rarity: 2, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 204, name: "コンパスシェル", rarity: 4, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
        Seed(id: 205, name: "マリーンマップ", rarity: 3, appearLocations: ["夕映の貝望台"], appearTimes: ["morning", "day", "evening", "night"]),
    ]

    for seed in seeds {
        let item = GameItem(itemId: seed.id,
                            name: seed.name,
                            rarity: seed.rarity,
                            appearLocations: seed.appearLocations,
                            appearTimes: seed.appearTimes,
                            count: 0)
        context.insert(item)
    }
    
    do {
        try context.save()
    } catch {
        print("初期アイテム登録失敗: \(error)")
    }
}
