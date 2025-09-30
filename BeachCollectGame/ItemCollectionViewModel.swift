import Foundation
import SwiftUI
import SwiftData

@MainActor
class ItemCollectionViewModel: ObservableObject {
    @Published var lastGottenItem: GameItem?
    @Published var lastGottenItemIsNew: Bool = false
    @Published var money: Int = 0

    var context: ModelContext?

    func acquire(_ item: GameItem) -> GameItem? {
        guard let ctx = context else { return nil }
        do {
            let targetID = item.id
            let descriptor = FetchDescriptor<GameItem>(
                predicate: #Predicate<GameItem> { $0.id == targetID }
            )
            if let existing = try ctx.fetch(descriptor).first {
                existing.count += 1
                if existing.discovered {
                    // 既に発見済みならレア度に応じたゴールドを加算
                    money += existing.duplicateGold
                    lastGottenItemIsNew = false
                } else {
                    // 初発見の場合は発見済みに更新
                    existing.discovered = true
                    lastGottenItemIsNew = true
                }
                try ctx.save()
                lastGottenItem = existing
                return existing
            } else {
                // まだ登録されていないアイテムの場合
                item.discovered = true
                item.count = 1
                ctx.insert(item)
                try ctx.save()
                lastGottenItem = item
                lastGottenItemIsNew = true
                return item
            }
        } catch {
            print("acquire error: \(error)")
            return nil
        }
    }
}
