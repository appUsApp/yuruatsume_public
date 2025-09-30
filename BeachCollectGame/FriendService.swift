import Foundation
import FirebaseFunctions
import FirebaseFirestore

enum FriendServiceError: Error {
    case callFailed(underlying: Error)
}

struct FriendService {
    // Functions 側とリージョンを一致させる（asia-northeast1）
    private static let fn = Functions.functions(region: "asia-northeast1")

    /// フレンド申請の承認（受信者のみ）
    static func approve(fromUid: String) async throws {
        do {
            _ = try await fn.httpsCallable("approveFriendRequest").call(["fromUid": fromUid])
        } catch {
            throw FriendServiceError.callFailed(underlying: error)
        }
    }

    /// 申請の辞退（ルールで status だけ変更可）
    static func decline(requestDocId: String) async throws {
        try await Firestore.firestore()
            .collection("friendRequests")
            .document(requestDocId)
            .updateData(["status": "declined"])
    }

    /// 申請の送信（参考：既に実装済みなら不要）
    static func send(from myUid: String, to toUid: String) async throws {
        try await Firestore.firestore()
            .collection("friendRequests")
            .addDocument(data: [
                "fromUid": myUid,
                "toUid": toUid,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ])
    }
    static func unfriend(otherUid: String) async throws {
        do { _ = try await fn.httpsCallable("unfriend").call(["otherUid": otherUid]) }
        catch { throw FriendServiceError.callFailed(underlying: error) }
    }
    static func cancelRequest(toUid: String) async throws {
        _ = try await fn.httpsCallable("cancelFriendRequest").call(["toUid": toUid])
    }
    
    /// フレンド申請（Functions経由・上限と重複はサーバで検証）
    static func request(toUid: String) async throws {
        do {
            _ = try await fn.httpsCallable("sendFriendRequest").call(["toUid": toUid])
        } catch {
            throw FriendServiceError.callFailed(underlying: error)
        }
    }

}
