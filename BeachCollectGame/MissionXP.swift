import Foundation
import FirebaseAuth
import FirebaseFirestore

enum MissionType: String { case daily, lifetime }

/// ミッション達成時に「一度だけ」XPを付与するヘルパー。
/// - 4:00 JSTの日付切替に対応
/// - users/{uid}/missionCompletions/{key} を作って二重加算を防止
enum MissionXP {
    /// 成功して付与したら true（既に達成済みなら false）
    static func awardOnce(type: MissionType, missionId: String, amount: Int = 10, now: Date = Date()) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let db = Firestore.firestore()

        let key: String = {
            switch type {
            case .daily:    return dailyKey(missionId, now: now)
            case .lifetime: return "lifetime_\(missionId)"
            }
        }()

        let userRef = db.document("users/\(uid)")
        let doneRef = db.document("users/\(uid)/missionCompletions/\(key)")

        return try await db.runTransaction { txn, _ in
            if (try? txn.getDocument(doneRef))?.exists == true {
                return false as Any
            }
            txn.setData([
                "type": type.rawValue,
                "missionId": missionId,
                "completedAt": FieldValue.serverTimestamp()
            ], forDocument: doneRef, merge: true)

            txn.updateData(["xp": FieldValue.increment(Int64(amount))], forDocument: userRef)
            return true as Any
        } as? Bool ?? false
    }

    /// 4:00 JST基準で日付キーを生成
    private static func dailyKey(_ missionId: String, now: Date) -> String {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var startOfDay = cal.startOfDay(for: now)
        let hour = cal.component(.hour, from: now)
        if hour < 4 { startOfDay = cal.date(byAdding: .day, value: -1, to: startOfDay)! }
        let y = cal.component(.year, from: startOfDay)
        let m = cal.component(.month, from: startOfDay)
        let d = cal.component(.day, from: startOfDay)
        return String(format: "%04d-%02d-%02d_%@", y, m, d, missionId)
    }
}
