import Foundation
import FirebaseFirestore
import FirebaseAuth

struct FriendCellVM: Identifiable {
    let id: String          // 相手UID
    let name: String
    let xp: Int
    let friendPoints: Int
    let imageID: String
    let effectID: String

    var level: Int { LevelService.level(forXP: xp) }
}

final class FriendHubViewModel: ObservableObject {
    @Published var friends: [FriendCellVM] = []
    @Published var outgoing: [FriendCellVM] = []
    @Published var incoming: [FriendCellVM] = []
    @Published var isLoading: Bool = false

    @Published private(set) var visited: Set<String> = []
    private var resetTimer: Timer?
    private var currentDayID: String
    private static let storageKey = "FriendHubVisited"

    private let db = Firestore.firestore()

    init() {
        currentDayID = Self.dayID()
        loadVisited()
        setupResetTimer()
    }

    // 3リストまとめて再読込
    func loadAll() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        await MainActor.run { isLoading = true }
        async let f1 = loadFriends(myUid: myUid)
        async let f2 = loadOutgoing(myUid: myUid)
        async let f3 = loadIncoming(myUid: myUid)
        let (a, b, c) = await (f1, f2, f3)
        await MainActor.run {
            self.friends = a
            self.outgoing = b
            self.incoming = c
            self.isLoading = false
        }
    }

    // MARK: - Loaders

    // フレンド一覧（users/{uid}.friends 配列ベース）
    private func loadFriends(myUid: String) async -> [FriendCellVM] {
        do {
            let userSnap = try await db.document("users/\(myUid)").getDocument()
            let my = try userSnap.data(as: UserDoc.self)
            let ids = my.friends
            return try await buildCells(for: ids)
        } catch {
            return []
        }
    }

    // 自分が送った pending 申請の相手一覧
    private func loadOutgoing(myUid: String) async -> [FriendCellVM] {
        do {
            let snap = try await db.collection("friendRequests")
                .whereField("fromUid", isEqualTo: myUid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            let ids = snap.documents.compactMap { try? $0.data(as: FriendRequestDoc.self).toUid }
            return try await buildCells(for: ids)
        } catch {
            return []
        }
    }

    // 自分宛の pending 申請の相手一覧
    private func loadIncoming(myUid: String) async -> [FriendCellVM] {
        do {
            let snap = try await db.collection("friendRequests")
                .whereField("toUid", isEqualTo: myUid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            let ids = snap.documents.compactMap { try? $0.data(as: FriendRequestDoc.self).fromUid }
            return try await buildCells(for: ids)
        } catch {
            return []
        }
    }

    // 表示セル生成（users / publicProfiles をまとめて取得）
    private func buildCells(for ids: [String]) async throws -> [FriendCellVM] {
        try await withThrowingTaskGroup(of: FriendCellVM?.self) { group in
            for uid in ids {
                group.addTask {
                    let userRef = self.db.document("users/\(uid)")
                    let pubRef  = self.db.document("publicProfiles/\(uid)")
                    async let uSnap = userRef.getDocument()
                    async let pSnap = pubRef.getDocument()

                    let user = try (try await uSnap).data(as: UserDoc.self)
                    let pub  = try? (try await pSnap).data(as: PublicProfileDoc.self)
                    let g = pub?.gallerySummary

                    let xp = user.xp ?? 0 // UserDoc.xp は Int (デフォルト0)
                    let fp = user.friendPoints
                    return FriendCellVM(
                        id: uid,
                        name: user.username ?? "名無し",
                        xp: xp,
                        friendPoints: fp,
                        imageID: g?.galleryImageID ?? "e01_0%",
                        effectID: g?.galleryEffectID ?? "MyGalleryGE01"
                    )
                }
            }
            var result: [FriendCellVM] = []
            for try await v in group {
                if let v { result.append(v) }
            }
            return result
        }
    }

    // MARK: - Actions

    /// 承認（incoming の行で使用）: Functions 経由で安全に承認
    func approve(requestFrom fromUid: String) async {
        await MainActor.run { isLoading = true }
        do {
            try await FriendService.approve(fromUid: fromUid)
            await loadAll()
        } catch {
            print("approve failed:", error)
        }
        await MainActor.run { isLoading = false }
    }

    /// 拒否（decline）: 受信者のみ status を "declined" に更新（他キーを書かない）
    func decline(requestFrom fromUid: String) async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        await MainActor.run { isLoading = true }
        do {
            // from==相手, to==自分, status==pending のものを1件だけ取って status だけ更新
            let snap = try await db.collection("friendRequests")
                .whereField("fromUid", isEqualTo: fromUid)
                .whereField("toUid", isEqualTo: myUid)
                .whereField("status", isEqualTo: "pending")
                .limit(to: 1)
                .getDocuments()

            guard let doc = snap.documents.first else {
                // 既に処理済み（accepted/declined）など
                await loadAll()
                await MainActor.run { isLoading = false }
                return
            }
            try await doc.reference.updateData(["status": "declined"])
            await loadAll()
        } catch {
            print("decline failed:", error)
        }
        await MainActor.run { isLoading = false }
    }

    /// フレンド削除: 双方の friends 配列から削除
    func removeFriend(_ otherUid: String) async {
        await MainActor.run { isLoading = true }
        do {
            try await FriendService.unfriend(otherUid: otherUid)
            await loadAll()
        } catch {
            print("unfriend failed:", error)
        }
        await MainActor.run { isLoading = false }
    }

    // MARK: - Visit Tracking

    private func loadVisited() {
        let dict = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:]
        visited = Set(dict.filter { $0.value == currentDayID }.map { $0.key })
    }

    func markVisited(id: String) {
        visited.insert(id)
        var dict = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:]
        dict[id] = currentDayID
        UserDefaults.standard.set(dict, forKey: Self.storageKey)
    }

    func hasVisited(_ id: String) -> Bool {
        visited.contains(id)
    }

    private func setupResetTimer() {
        let next = Self.nextResetDate()
        resetTimer?.invalidate()
        resetTimer = Timer(fire: next, interval: 0, repeats: false) { [weak self] _ in
            self?.resetForNewDay()
        }
        if let resetTimer { RunLoop.main.add(resetTimer, forMode: .default) }
    }

    private func resetForNewDay() {
        visited.removeAll()
        currentDayID = Self.dayID()
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        setupResetTimer()
    }

    private static func dayID(for date: Date = Date()) -> String {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var day = cal.startOfDay(for: date)
        if cal.component(.hour, from: date) < 4 {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", comps.year!, comps.month!, comps.day!)
    }

    private static func nextResetDate(from date: Date = Date()) -> Date {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let today4 = cal.date(bySettingHour: 4, minute: 0, second: 0, of: date)!
        if date < today4 {
            return today4
        } else {
            return cal.date(byAdding: .day, value: 1, to: today4)!
        }
    }
    
    func cancelOutgoing(to toUid: String) async {
        await MainActor.run { isLoading = true }
        do {
            try await FriendService.cancelRequest(toUid: toUid)
            await loadAll()
        } catch {
            print("cancel outgoing failed:", error)
        }
        await MainActor.run { isLoading = false }
    }

    deinit {
        resetTimer?.invalidate()
    }
}
