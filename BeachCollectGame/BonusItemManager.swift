import Foundation
import SwiftData

struct BonusItemManager {
    private static let storageKey = "BonusItemManager.selected"
    private static let rerollKey  = "BonusItemManager.rerolled"

    // 6時間スロットのキー（次の切替時刻から逆算）
    static func slotKey(for date: Date = Date()) -> String {
        let next = nextSwitchDate(from: date)
        let start = Calendar.current.date(byAdding: .hour, value: -6, to: next) ?? date
        return String(Int(start.timeIntervalSince1970))
    }

    /// アクセス可能ロケーションを含むレア度候補から1つ抽選
    /// - Parameters:
    ///   - rarity: 1...4
    ///   - excluding: 除外する itemId（通常は消費済み）
    ///   - allowFallbackToExcluded: 全滅時に除外無視でフォールバックするか
    private static func pickCandidate(
        rarity: Int,
        allItems: [GameItem],
        accessible: Set<String>,
        excluding: Set<Int>,
        allowFallbackToExcluded: Bool
    ) -> GameItem? {
        let pool = allItems.filter {
            $0.rarity == rarity && $0.appearLocations.contains { accessible.contains($0) }
        }
        // まずは消費済みを除外したプールから
        let primary = pool.filter { !excluding.contains($0.itemId) }
        if let picked = primary.randomElement() {
            return picked
        }
        // 全滅なら（表示はされないが）次回のために保存を更新できるようフォールバックを許可
        if allowFallbackToExcluded {
            return pool.randomElement()
        }
        return nil
    }

    /// 現在スロットのボーナス一覧を返す（必要なら消費済みを置換して再抽選）
    static func currentBonusItems(
        allItems: [GameItem],
        ownedMaps: [OwnedMapItem],
        consumed: Set<Int>
    ) -> [GameItem] {
        let slotKey = slotKey()

        let accessible = Set(["BeachScratch", "FishAppear"] + ownedMaps.map { $0.name })
        var result: [GameItem] = []

        // スロット保存を読み込み
        var storage = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String: Int]] ?? [:]
        var selected = storage[slotKey] ?? [:]

        // レア度ごとに、未設定 or 消費済みなら再抽選して上書き
        for rarity in 1...4 {
            let key = "\(rarity)"
            let alreadyId = selected[key]

            // 既存アイテムが有効かどうか
            let alreadyItem: GameItem? = {
                guard let id = alreadyId else { return nil }
                return allItems.first(where: { $0.itemId == id })
            }()

            let needsReselect = (alreadyItem == nil)

            if needsReselect {
                if let newItem = pickCandidate(
                    rarity: rarity,
                    allItems: allItems,
                    accessible: accessible,
                    excluding: consumed,
                    allowFallbackToExcluded: true
                ) {
                    selected[key] = newItem.itemId
                    if !consumed.contains(newItem.itemId) {
                        result.append(newItem)
                    }
                } else {
                    // 候補全滅（理論上ほぼ無い）が起きた場合はキーを消しておく
                    selected.removeValue(forKey: key)
                }
            } else if let item = alreadyItem, !consumed.contains(item.itemId) {
                // 既存が有効で未消費
                result.append(item)
            }
        }

        // 保存（このスロットのみ更新）
        storage[slotKey] = selected
        UserDefaults.standard.set(storage, forKey: storageKey)

        return result
    }

    static func canReroll(for _: Date = Date()) -> Bool {
        // Allow rerolling without restrictions
        return true
    }

    /// リロール：各レア度を必ず再抽選して保存を差し替える
    static func rerollBonusItems(
        allItems: [GameItem],
        ownedMaps: [OwnedMapItem],
        consumed: Set<Int>
    ) -> [GameItem] {
        let slotKey = slotKey()

        let accessible = Set(["BeachScratch", "FishAppear"] + ownedMaps.map { $0.name })
        var result: [GameItem] = []
        var selected: [String: Int] = [:]

        for rarity in 1...4 {
            if let item = pickCandidate(
                rarity: rarity,
                allItems: allItems,
                accessible: accessible,
                excluding: consumed,
                allowFallbackToExcluded: true
            ) {
                selected["\(rarity)"] = item.itemId
                if !consumed.contains(item.itemId) {
                    result.append(item)
                }
            }
        }

        var storage = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String: Int]] ?? [:]
        storage[slotKey] = selected
        UserDefaults.standard.set(storage, forKey: storageKey)
        UserDefaults.standard.set(slotKey, forKey: rerollKey)

        return result
    }

    /// 4/10/16/22時切替（日本語環境でもCalendar.currentに依存）
    static func nextSwitchDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let nextHour: Int
        switch hour {
        case 0..<4:   nextHour = 4
        case 4..<10:  nextHour = 10
        case 10..<16: nextHour = 16
        case 16..<22: nextHour = 22
        default:
            nextHour = 4
            if let day = components.day { components.day = day + 1 }
        }
        components.hour = nextHour
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}
