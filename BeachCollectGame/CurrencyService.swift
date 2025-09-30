import Foundation
import FirebaseFirestore

actor CurrencyService {
    static let shared = CurrencyService()
    private let db = Firestore.firestore()
    private init() {}

    enum Asset: String {
        case gold
        case bubbleCrystal
        case bubbleStar
        case friendPoints

        var fieldPath: String {
            switch self {
            case .friendPoints:
                return "friendPoints"
            default:
                return "currencies.\(rawValue)"
            }
        }
    }

    /// Increment a currency atomically using FieldValue.increment.
    /// Optionally increments XP in the same operation.
    func increment(
        _ asset: Asset,
        by amount: Int,
        uid: String,
        xp: Int = 0
    ) async throws {
        var data: [String: Any] = [
            asset.fieldPath: FieldValue.increment(Int64(amount))
        ]
        if xp != 0 {
            data["xp"] = FieldValue.increment(Int64(xp))
        }
        try await db.document(FSPath.user(uid)).updateData(data)
    }

    /// Increment XP without modifying any currency.
    func incrementXP(by amount: Int = 1, uid: String) async throws {
        try await db.document(FSPath.user(uid)).updateData([
            "xp": FieldValue.increment(Int64(amount))
        ])
    }

    /// Purchase operation that decrements currency inside a Firestore transaction.
    /// Returns true if the deduction succeeded.
    func purchase(_ asset: Asset, cost: Int, uid: String) async -> Bool {
        guard cost > 0 else { return true }
        do {
            return try await db.runTransaction { txn, errorPointer in
                let ref = self.db.document(FSPath.user(uid))
                let snap: DocumentSnapshot
                do {
                    snap = try txn.getDocument(ref)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
                guard let data = snap.data() else { return false }
                let current: Int
                if asset == .friendPoints {
                    current = data["friendPoints"] as? Int ?? 0
                } else {
                    let currencies = data["currencies"] as? [String: Any]
                    current = currencies?[asset.rawValue] as? Int ?? 0
                }
                if current < cost {
                    return false
                }
                txn.updateData([asset.fieldPath: current - cost], forDocument: ref)
                return true
            } as? Bool ?? false
        } catch {
            return false
        }
    }

    /// Increment friend points and record the like timestamp atomically.
    func likeUser(myUid: String, targetUid: String) async throws {
        let myRef = db.document(FSPath.user(myUid))
        let likeRef = db.collection("likeRecords").document(myUid)
            .collection("targets").document(targetUid)
        let batch = db.batch()
        batch.updateData([Asset.friendPoints.fieldPath: FieldValue.increment(Int64(1))], forDocument: myRef)
        batch.setData(["lastLikedAt": FieldValue.serverTimestamp()], forDocument: likeRef, merge: true)
        try await batch.commit()
    }
}

