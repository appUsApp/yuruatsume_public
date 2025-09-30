import Foundation
import SwiftData

@MainActor
class MonsterCollectionViewModel: ObservableObject {
    var context: ModelContext?

    func registerDefeat(of monster: Monster) -> (Int, Bool) {
        guard let ctx = context else { return (0, false) }
        do {
            let mid = monster.id
            let descriptor = FetchDescriptor<MonsterRecord>(
                predicate: #Predicate { $0.monsterId == mid }
            )
            if let record = try ctx.fetch(descriptor).first {
                record.count += 1
                let wasRegistered = record.hasPage
                if !wasRegistered {
                    record.hasPage = true
                }
                try ctx.save()
                return (record.count, !wasRegistered)
            }
        } catch {
            print("monster register error: \(error)")
        }
        return (0, false)
    }

    /// Fetch MonsterRecord for given monster
    func record(for monster: Monster) -> MonsterRecord? {
        guard let ctx = context else { return nil }
        let mid = monster.id
        let descriptor = FetchDescriptor<MonsterRecord>(
            predicate: #Predicate { $0.monsterId == mid }
        )
        return try? ctx.fetch(descriptor).first
    }

    /// Increment preCount for monsters not yet obtained and return updated count
    func incrementPreCount(for monster: Monster) -> Int {
        guard let ctx = context else { return 0 }
        let mid = monster.id
        let descriptor = FetchDescriptor<MonsterRecord>(
            predicate: #Predicate { $0.monsterId == mid }
        )
        if let record = try? ctx.fetch(descriptor).first {
            record.preCount += 1
            try? ctx.save()
            return record.preCount
        }
        return 0
    }
}
