import Foundation

/// ゴールド獲得のローカルバッファ
actor CurrencyEarningsBuffer {
    static let shared = CurrencyEarningsBuffer()
    private let goldKey = "CurrencyEarningsBuffer.pendingGold"
    private let xpKey   = "CurrencyEarningsBuffer.pendingXP"
    /// この値以上貯まっていたら自動フラッシュ
    private let flushThreshold = 100

    private var pendingGold: Int
    private var pendingXP: Int

    init() {
        let d = UserDefaults.standard
        pendingGold = d.integer(forKey: goldKey)
        pendingXP   = d.integer(forKey: xpKey)
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(pendingGold, forKey: goldKey)
        d.set(pendingXP,   forKey: xpKey)
    }

    /// ゴールド獲得をローカルに積む（即Firestoreへは書かない）
    func earnGold(_ amount: Int, xp: Int = 0) {
        guard amount > 0 else { return }
        pendingGold &+= amount
        if xp > 0 { pendingXP &+= xp }
        persist()
    }

    /// 閾値以上なら（または force=true なら）フラッシュ
    func flushGoldIfNeeded(uid: String, force: Bool = false) async {
        guard pendingGold > 0 || pendingXP > 0 else { return }
        if !force && pendingGold < flushThreshold { return }
        await flushGoldNow(uid: uid)
    }

    /// いま貯まっている分を一括で反映
    func flushGoldNow(uid: String) async {
        guard pendingGold > 0 || pendingXP > 0 else { return }
        let delta = pendingGold
        let xp    = pendingXP
        pendingGold = 0
        pendingXP   = 0
        persist()
        do {
            try await CurrencyService.shared.increment(.gold, by: delta, uid: uid, xp: xp)
        } catch {
            pendingGold &+= delta
            pendingXP   &+= xp
            persist()
        }
    }

    /// アカウント削除, 初期化
    func reset() {
        pendingGold = 0
        pendingXP = 0
        persist()
    }
}
