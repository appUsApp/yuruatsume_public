import Foundation
import SwiftData

@MainActor
class GachaViewModel: ObservableObject {
    var context: ModelContext?

    enum GachaType {
        case premium
        case pickup
    }

    struct Result {
        let record: MonsterRecord
        let isNew: Bool
    }

    /// Rarity appearance rates for the gacha.
    /// Index corresponds to rarity value (1-5).
    private let rarityRates: [Double] = [0.0, 0.5, 0.35, 0.10, 0.05]

    var rarityRateInfo: [(rarity: Int, rate: Double)] {
        rarityRates.enumerated().map { ($0.offset + 1, $0.element) }
    }

    func draw(type: GachaType, count: Int) -> [Result] {
        guard let ctx = context else { return [] }
        ensureMonsterPool(context: ctx)
        var results: [Result] = []
        for _ in 0..<count {
            if let record = randomRecord(for: type, context: ctx) {
                let wasObtained = record.obtained
                record.obtained = true
                results.append(Result(record: record, isNew: !wasObtained))
            }
        }
        try? ctx.save()
        return results
    }

    private func randomRarity() -> Int {
        var rnd = Double.random(in: 0..<1)
        for (index, rate) in rarityRates.enumerated() {
            rnd -= rate
            if rnd < 0 { return index + 1 }
        }
        return 5
    }

    private func randomRecord(for type: GachaType, context: ModelContext) -> MonsterRecord? {
        let rarity = randomRarity()

        let descriptor: FetchDescriptor<MonsterRecord>
        switch type {
        case .premium:
            descriptor = FetchDescriptor<MonsterRecord>(
                predicate: #Predicate { $0.rarity == rarity }
            )
        case .pickup:
            let pickupIds: [Int] = MonsterData.sand.map { MonsterData.id(for: $0) }
            descriptor = FetchDescriptor<MonsterRecord>(
                predicate: #Predicate { pickupIds.contains($0.monsterId) && $0.rarity == rarity }
            )
        }
        if let records = try? context.fetch(descriptor), let record = records.randomElement() {
            return record
        }

        // ① 同タイプの全レアリティへ緩和
        let relaxed: FetchDescriptor<MonsterRecord>
        switch type {
        case .premium:
            relaxed = FetchDescriptor<MonsterRecord>() // 全モンスター
        case .pickup:
            let pickupIds: [Int] = MonsterData.sand.map { MonsterData.id(for: $0) }
            relaxed = FetchDescriptor<MonsterRecord>(
                predicate: #Predicate { pickupIds.contains($0.monsterId) }
            )
        }
        if let records = try? context.fetch(relaxed), let record = records.randomElement() {
            return record
        }

        // ② まだ空なら初期投入してから再取得（新規端末対策）
        ensureMonsterPool(context: context)
        if let records = try? context.fetch(relaxed), let record = records.randomElement() {
            return record
        }

        // ③ 最後の保険：全レコードから
        if let all = try? context.fetch(FetchDescriptor<MonsterRecord>()),
           let any = all.randomElement() {
            return any
        }
        return nil
        }

        /// SwiftDataにモンスターレコードが無ければ初期投入
        private func ensureMonsterPool(context: ModelContext) {
            let count = (try? context.fetch(FetchDescriptor<MonsterRecord>()).count) ?? 0
            if count == 0 {
                initializeMonstersIfNeeded(context: context)
            }
        }
}
