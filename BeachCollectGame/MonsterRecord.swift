import Foundation
import SwiftData

@Model class MonsterRecord {
    var id: UUID
    /// Stable monster identifier
    var monsterId: Int
    var name: String
    /// 1 (common) - 5 (legendary)
    var rarity: Int
    var count: Int
    /// Set to true once obtained from gacha
    var obtained: Bool
    var hasPage: Bool
    /// Count of defeats before officially obtaining
    var preCount: Int

    init(id: UUID = UUID(),
         monsterId: Int,
         name: String,
         rarity: Int = 1,
         count: Int = 0,
         obtained: Bool = false,
         hasPage: Bool = false,
         preCount: Int = 0) {
        self.id = id
        self.monsterId = monsterId
        self.name = name
        self.rarity = rarity
        self.count = count
        self.obtained = obtained
        self.hasPage = hasPage
        self.preCount = preCount
    }

    /// Image name derived from monster ID
    var imageName: String { "c\(monsterId)" }

    var isRegistered: Bool { hasPage }
    var isFullyRegistered: Bool { count >= 3 }
}

func initializeMonstersIfNeeded(context: ModelContext) {
    let existingCount = try? context.fetch(FetchDescriptor<MonsterRecord>()).count
    if let c = existingCount, c > 0 { return }

    for name in MonsterData.all {
        let mid = MonsterData.id(for: name)
        let record = MonsterRecord(monsterId: mid,
                                   name: name,
                                   rarity: MonsterData.rarity(for: name),
                                   count: 0,
                                   obtained: false,
                                   hasPage: false,
                                   preCount: 0)
        context.insert(record)
    }

    try? context.save()
}
