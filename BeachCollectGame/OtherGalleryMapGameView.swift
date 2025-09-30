import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AVFoundation

/// Displays another user's MyGallery configuration as a scratchable map.
struct OtherGalleryMapGameView: View {
    let targetUserUid: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timeManager: TimeOfDayManager
    @State private var config: GalleryConfigDoc? = nil
    @State private var liked = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var timeRemaining = 120
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showLeaveConfirm = false
    @State private var showFriendRequest = false
    @State private var isLeaving = false
    @State private var otherUserName = ""
    @StateObject private var stamina = StaminaService.shared
    @State private var isBusy = false
    @State private var lastVisitorUID: String? = nil
    @State private var visitHistoryEntries: [VisitHistoryEntry] = []
    @AppStorage("OtherGalleryMapGameView.visitHistory") private var visitHistoryRawValue = "[]"
    @AppStorage("OtherGalleryMapGameView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false
    @State private var popupMessage: String? = nil

    private let visitHistoryLimit = 12
    private let visitHistoryRetention: TimeInterval = 60 * 60 * 6 // 6時間は抽選対象から外す

    enum LeaveTrigger { case timeout, manual }

    init(targetUserUid: String? = nil) {
        self.targetUserUid = targetUserUid
    }

    var body: some View {
        ZStack {
            if let cfg = config {
                BeachScratchView(customBackground: AnyView(RemoteGalleryBackgroundView(config: cfg)),
                                  allowedMonsterIDs: cfg.monsterIDs,
                                  allowedItemIDs: cfg.itemIDs,
                                  isOtherGallery: true)
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }

            if showLeaveConfirm {
                Color.black.opacity(0.4).ignoresSafeArea()
                LeaveConfirmPopupView(onCancel: { showLeaveConfirm = false }, onConfirm: {
                    showLeaveConfirm = false
                    leaveGallery(trigger: .manual)
                })
            }

            if showFriendRequest, let cfg = config {
                Color.black.opacity(0.4).ignoresSafeArea()
                FriendRequestPopupView(name: otherUserName,
                                       imageID: cfg.galleryImageID,
                                       effectID: cfg.galleryEffectID,
                                       onRequest: {
                                           Task {
                                               try? await sendFriendRequest(to: cfg.userId)
                                               await MainActor.run {
                                                   showFriendRequest = false
                                                   dismiss()
                                               }
                                           }
                                       },
                                       onClose: {
                                           showFriendRequest = false
                                           dismiss()
                                       })
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "みんなのギャラリー",
                    messages: [
                        "ここは他のプレイヤーが設定したギャラリーの世界",
                        "ここではガチャで当てていないシオノコとも出会える。たくさん会うと、泡沫星での交換が簡単に！",
                        "いいねやフレンド申請もしてみよう！"
                    ]
                ) {
                    withAnimation {
                        hasSeenGuide = true
                        showGuide = false
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            Task { await loadVisitHistory() }
            // 既存ローディング
            if config == nil {
                if let uid = targetUserUid {
                    Task { await loadConfig(for: uid) }
                } else {
                    Task { await loadRecentVisitor() }
                }
            }
            // ▼ stamina 監視開始＆初期化＆スロット確認
            if let myUid = Auth.auth().currentUser?.uid {
                stamina.start(uid: myUid)
                Task { await stamina.ensureDefaults() }
            }
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }

        .onReceive(timer) { _ in
            guard timeRemaining > 0 else { return }
            timeRemaining -= 1
            if timeRemaining == 0 { leaveGallery(trigger: .timeout) }
        }
        .onDisappear {
            stopTimer()
            timeManager.stopOverrideBGM()
            stamina.stop()
        }
        .safeAreaInset(edge: .top) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    PlayerStatusView()
                    HintStripView(staminaService: stamina, popupMessage: $popupMessage)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(alignment: .center) {
                Button(action: { showLeaveConfirm = true }) {
                    Image("e01_0%")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.8)
                        .padding(8)
                }
                .frame(width: 55, height: 55)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color(hex: "#86C3D1", alpha: 0.1))
                        )
                )                .clipShape(Circle())
                .shadow(radius: 2)

                Spacer()

                VStack(spacing: 6) {
                    if !otherUserName.isEmpty {
                        Text("\(otherUserName)のギャラリー")
                            .font(.headline)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(radius: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text("\(timeRemaining)")
                        .font(.headline)
                        .monospacedDigit()
                }

                Spacer()

                Button(action: { performLikeWithStamina() }) {
                    Image(liked ? "HeartIconTapped" : "HeartIcon")
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .animation(.easeInOut(duration: 0.15), value: liked)
                }
                .frame(width: 55, height: 55)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color(hex: "#86C3D1", alpha: 0.1))
                        )
                )                .clipShape(Circle())
                .shadow(radius: 2)
                .disabled(liked || config == nil || isBusy || stamina.isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .overlay {
            ZStack {
                if isBusy || stamina.isLoading {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                }

                if let message = popupMessage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { popupMessage = nil }
                        SimpleMessagePopupView(message: message) {
                            popupMessage = nil
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isBusy || stamina.isLoading)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

        private func loadInitialConfig() async {
            if let uid = targetUserUid, !uid.isEmpty {
                await loadConfig(for: uid)
            } else {
                await loadRecentVisitor()
            }
        }

        private func loadConfig(for uid: String) async {
            let db = Firestore.firestore()
            do {
                let profileSnap = try await db.collection("publicProfiles").document(uid).getDocument()
                guard let profile = try? profileSnap.data(as: PublicProfileDoc.self),
                      let summary = profile.gallerySummary else { return }

                let cfg = GalleryConfigDoc(
                    id: uid,
                    userId: uid,
                    backgroundID: summary.backgroundID,
                    backgroundEffectID: summary.backgroundEffectID,
                    galleryImageID: summary.galleryImageID,
                    monsterIDs: summary.monsterIDs,
                    itemIDs: summary.itemIDs,
                    galleryEffectID: summary.galleryEffectID,
                    bgmID: summary.bgmID
                )

                let userSnap = try? await db.document("users/\(uid)").getDocument()
                let userDoc = try? userSnap?.data(as: UserDoc.self)

                await MainActor.run {
                    self.config = cfg
                    self.otherUserName = userDoc?.username ?? "名無し"
                    timeManager.playMapBGM(name: cfg.bgmID)
                }
                await checkLikeStatus(targetUID: uid)
            } catch {
                print("Failed to fetch config for uid:", error)
            }
        }

    /// ランダムに他人の公開ギャラリーを取得（軽量版：rand + limit）
    private func loadRecentVisitor() async {
        let db = Firestore.firestore()
        var exclusionSet: Set<String> = []
        do {
            exclusionSet = try await MainActor.run { () -> Set<String> in
                try ensureVisitHistoryIsFresh()
                return Set(visitHistoryEntries.map(\.uid))
            }
        } catch {
            print("Failed to load visit history:", error)
        }
        do {
            let myUid = Auth.auth().currentUser?.uid ?? ""
            var afterDoc: DocumentSnapshot? = nil
            var hops = 0
            let maxHops = 5                 // ページ送り最大回数
            let pageSize = 3               // 先頭ページの候補数（読み取り抑制と分散のバランス）
            let maxHistoryPrunes = max(visitHistoryLimit, 1)
            var prunedCount = 0

            while prunedCount <= maxHistoryPrunes {
                if hops >= maxHops {
                    do {
                        guard prunedCount < maxHistoryPrunes else { break }
                        guard let removed = try await dropOldestVisitHistoryEntry() else { break }
                        exclusionSet.remove(removed)
                        afterDoc = nil
                        hops = 0
                        prunedCount += 1
                        continue
                    } catch {
                        print("Failed to prune visit history:", error)
                        break
                    }
                }

                var q: Query = db.collection("publicProfiles")
                    .whereField("allowVisit", isEqualTo: true)
                    .order(by: "lastActiveAt", descending: true)   // 直近順
                    .order(by: FieldPath.documentID())             // タイブレーク
                    .limit(to: pageSize)
                if let afterDoc { q = q.start(afterDocument: afterDoc) }


                let snap = try await q.getDocuments()
                let docs = snap.documents
                if docs.isEmpty {
                    // wrap-around
                    afterDoc = nil
                    hops += 1
                    continue
                }
                // デコードして候補抽出（自分/直前同一/ギャラリー未設定は除外）
                var candidates: [(doc: DocumentSnapshot, profile: PublicProfileDoc, uid: String)] = []
                for d in docs {
                    if let p = try? d.data(as: PublicProfileDoc.self) {
                        let uid = p.id ?? d.documentID
                        if uid != myUid && p.gallerySummary != nil {
                            if uid != (lastVisitorUID ?? "") && !exclusionSet.contains(uid) {
                                candidates.append((d, p, uid))
                            }
                        }
                    }
                }
                if candidates.isEmpty {
                    // このページに条件を満たす候補が無ければ次のページへ
                    afterDoc = docs.last
                    hops += 1
                    continue
                }


                // ページ内からランダムに1件
                let pick = candidates.randomElement()!
                let profile = pick.profile
                let uid = pick.uid

                guard let summary = profile.gallerySummary else { return }
                let cfg = GalleryConfigDoc(
                    id: uid,
                    userId: uid,
                    backgroundID: summary.backgroundID,
                    backgroundEffectID: summary.backgroundEffectID,
                    galleryImageID: summary.galleryImageID,
                    monsterIDs: summary.monsterIDs,
                    itemIDs: summary.itemIDs,
                    galleryEffectID: summary.galleryEffectID,
                    bgmID: summary.bgmID
                )

                let userSnap = try? await db.document("users/\(uid)").getDocument()
                let userDoc = try? userSnap?.data(as: UserDoc.self)

                await MainActor.run {
                    self.config = cfg
                    self.otherUserName = userDoc?.username ?? "名無し"
                    self.lastVisitorUID = uid
                    timeManager.playMapBGM(name: cfg.bgmID)
                }
                await registerVisit(uid: uid)
                await checkLikeStatus(targetUID: uid)
                return
            }


        } catch {
            print("loadRecentVisitor failed:", error)
        }
    }


    private func checkLikeStatus(targetUID: String) async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("likeRecords").document(myUid).collection("targets").document(targetUID)
        do {
            let snapshot = try await docRef.getDocument()
            if let data = snapshot.data(), let ts = data["lastLikedAt"] as? Timestamp {
                let date = ts.dateValue()
                if Calendar.current.isDateInToday(date) {
                    await MainActor.run { liked = true }
                }
            }
        } catch {
            print("Failed to check like status:", error)
        }
    }

    private func likeCurrent() {
        guard let cfg = config, let myUid = Auth.auth().currentUser?.uid else { return }
        liked = true
        SoundEffect.play("GachaEffect", player: &audioPlayer)

        Task {
            do {
                try await CurrencyService.shared.likeUser(myUid: myUid, targetUid: cfg.userId)
            } catch {
                print("Failed to like:", error)
            }
        }
    }
    
    /// Like 実行前にスタミナ消費（Functions）を通す。足りなければ Like しない。
    private func performLikeWithStamina() {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                _ = try await stamina.consumeForLike() // 1消費（スロット跨ぎなら満タン→1減）
                likeCurrent()
            } catch {
                print("performLikeWithStamina: \(error)")
            }
            await MainActor.run { isBusy = false }
        }
    }


    private func stopTimer() {
        timer.upstream.connect().cancel()
    }

    private func leaveGallery(trigger: LeaveTrigger) {
        guard !isLeaving else { return }
        isLeaving = true
        showLeaveConfirm = false
        stopTimer()
        guard let uid = config?.userId else {
            dismiss()
            return
        }
        Task {
            let friend = await isFriend(uid)
            let pending = await hasPendingRequest(uid)
            if friend || pending {
                await MainActor.run { dismiss() }
            } else {
                await MainActor.run { showFriendRequest = true }
            }
        }
    }

    private func isFriend(_ uid: String) async -> Bool {
        guard let myUid = Auth.auth().currentUser?.uid else { return false }
        do {
            let snap = try await Firestore.firestore().document("users/\(myUid)").getDocument()
            let me = try snap.data(as: UserDoc.self)
            return me.friends.contains(uid)
        } catch {
            return false
        }
    }

    private func hasPendingRequest(_ uid: String) async -> Bool {
        guard let myUid = Auth.auth().currentUser?.uid else { return false }
        let db = Firestore.firestore()
        do {
            let outgoing = try await db.collection("friendRequests")
                .whereField("fromUid", isEqualTo: myUid)
                .whereField("toUid", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            if !outgoing.documents.isEmpty { return true }
            let incoming = try await db.collection("friendRequests")
                .whereField("fromUid", isEqualTo: uid)
                .whereField("toUid", isEqualTo: myUid)
                .whereField("status", isEqualTo: "pending")
                .getDocuments()
            return !incoming.documents.isEmpty
        } catch {
            return false
        }
    }

    private func sendFriendRequest(to receiverUid: String) async throws {
      try await FriendService.request(toUid: receiverUid)
    }
}

private struct LeaveConfirmPopupView: View {
    var onCancel: () -> Void
    var onConfirm: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack {
                        Spacer()
                        Text("このビーチから離れますか？")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .padding(.bottom, 36)
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onCancel()
                            }) {
                                Image("Cancel Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 150, height: 55)
                            }

                            Button(action: {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onConfirm()
                            }) {
                                Image("OK Button")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 150, height: 55)
                            }
                        }
                        .padding(.bottom, 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10) 
                }
        }
    }
}

private struct FriendRequestPopupView: View {
    let name: String
    let imageID: String
    let effectID: String
    var onRequest: () -> Void
    var onClose: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay(alignment: .top) {
                    VStack(spacing: 16) {
                        Text("フレンドになりますか？")
                            .font(.headline)
                        ProfileCircleAvatar(imageID: imageID, effectID: effectID, size: 80)
                        Text(name)
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 16) {
                            Button("閉じる") {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onClose()
                            }
                            .buttonStyle(.bordered)

                            Button("フレンド申請") {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onRequest()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.bottom, 32)
                    }
                    .frame(height: 240)
                    .padding(.top, 24)
                }
        }
    }
}

private struct RemoteGalleryBackgroundView: View {
    let config: GalleryConfigDoc
    @State private var positions: [CGPoint] = []
    private let iconSize: CGFloat = 50

    private var icons: [String] { config.monsterIDs + config.itemIDs }

    private func generatePositions(in size: CGSize, count: Int) -> [CGPoint] {
        var result: [CGPoint] = []
        let radius = iconSize
        for _ in 0..<count {
            var candidate = CGPoint(x: .random(in: radius...size.width - radius),
                                   y: .random(in: radius...size.height - radius))
            var attempts = 0
            while attempts < 50 {
                var overlaps = false
                for p in result {
                    if hypot(p.x - candidate.x, p.y - candidate.y) < radius {
                        overlaps = true
                        break
                    }
                }
                if !overlaps { break }
                candidate = CGPoint(x: .random(in: radius...size.width - radius),
                                   y: .random(in: radius...size.height - radius))
                attempts += 1
            }
            result.append(candidate)
        }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let galleryWidth = min(proxy.size.width, proxy.size.height) * 0.85

            ZStack {
                Image(config.backgroundID)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Image(config.backgroundEffectID)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ZStack {
                    Image(config.galleryImageID)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: galleryWidth)
                        .overlay {
                            GeometryReader { geo in
                                ForEach(Array(icons.enumerated()), id: \.offset) { index, name in
                                    if positions.indices.contains(index) {
                                        Image(name)
                                            .resizable()
                                            .frame(width: iconSize, height: iconSize)
                                            .position(positions[index])
                                    }
                                }
                                Color.clear
                                    .onAppear {
                                        positions = generatePositions(in: geo.size, count: icons.count)
                                    }
                                    .onChange(of: icons.count) {
                                        positions = generatePositions(in: geo.size, count: icons.count)
                                    }
                            }
                        }

                    Image(config.galleryEffectID)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: galleryWidth)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

extension OtherGalleryMapGameView {
    private struct VisitHistoryEntry: Codable, Equatable {
        let uid: String
        let visitedAt: Date
    }

    @MainActor
    private func loadVisitHistory() async {
        do {
            try ensureVisitHistoryIsFresh()
        } catch {
            print("Failed to decode visit history:", error)
        }
    }

    @MainActor
    private func ensureVisitHistoryIsFresh() throws {
        let history = try decodeVisitHistory()
        let now = Date()
        let filtered = history
            .filter { now.timeIntervalSince($0.visitedAt) < visitHistoryRetention }
            .sorted { $0.visitedAt < $1.visitedAt }
        if filtered.count != history.count {
            persistVisitHistory(filtered)
        } else {
            visitHistoryEntries = filtered
        }
    }

    @MainActor
    private func registerVisit(uid: String) {
        let now = Date()
        var history = visitHistoryEntries
            .filter { now.timeIntervalSince($0.visitedAt) < visitHistoryRetention && $0.uid != uid }
        history.append(VisitHistoryEntry(uid: uid, visitedAt: now))
        history.sort { $0.visitedAt < $1.visitedAt }
        if history.count > visitHistoryLimit {
            history = Array(history.suffix(visitHistoryLimit))
        }
        persistVisitHistory(history)
    }

    @MainActor
    private func persistVisitHistory(_ history: [VisitHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(history),
              let json = String(data: data, encoding: .utf8) else {
            visitHistoryRawValue = "[]"
            visitHistoryEntries = []
            return
        }
        visitHistoryRawValue = json
        visitHistoryEntries = history
    }

    @MainActor
    private func dropOldestVisitHistoryEntry() throws -> String? {
        try ensureVisitHistoryIsFresh()
        guard !visitHistoryEntries.isEmpty else { return nil }
        var history = visitHistoryEntries
        let removed = history.removeFirst()
        persistVisitHistory(history)
        return removed.uid
    }

    private func decodeVisitHistory() throws -> [VisitHistoryEntry] {
        guard let data = visitHistoryRawValue.data(using: .utf8) else { return [] }
        return try JSONDecoder().decode([VisitHistoryEntry].self, from: data)
    }
}

#Preview {
    OtherGalleryMapGameView()
}

