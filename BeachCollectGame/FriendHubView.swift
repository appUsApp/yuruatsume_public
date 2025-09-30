import SwiftUI
import AVFoundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

struct FriendHubView: View {
    enum Tab: Int, CaseIterable { case friend, request, approval }

    @State private var selection: Tab = .friend
    @Environment(\.dismiss) private var dismiss
    @State private var audioPlayer: AVAudioPlayer? = nil
    @StateObject private var vm = FriendHubViewModel()
    @State private var path: [String] = []
    @State private var targetToRemove: FriendCellVM? = nil
    @State private var targetToWithdraw: FriendCellVM? = nil
    @State private var selectedFriend: FriendCellVM? = nil
    // フレンド申請ポップアップ関連
    @State private var showUIDPopup = false
    @State private var uidInput: String = ""
    @State private var foundProfile: FriendCellVM? = nil
    @State private var showFriendRequestPopup = false
    @State private var showNotFoundPopup = false
    @State private var statusMessage: String? = nil
    @AppStorage("FriendHubView.hasSeenGuide") private var hasSeenGuide = false
    @State private var showGuide = false

    var body: some View {
        NavigationStack(path: $path) {
        ZStack {
            TabView(selection: $selection) {
                // フレンド一覧
                List {
                    Section {
                        ForEach(vm.friends) { cell in
                            HStack(spacing: 12) {
                                ProfileCircleAvatar(imageID: cell.imageID, effectID: cell.effectID, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cell.name).font(.headline)
                                    HStack(spacing: 8) {
                                        Text("Lv.\(cell.level)")
                                        HStack(spacing: 2) {
                                            Image("HeartIconTapped")
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                            Text("\(cell.friendPoints)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("訪れる") {
                                    SoundEffect.play("moveSand", player: &audioPlayer)
                                    vm.markVisited(id: cell.id)
                                    path.append(cell.id)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(vm.hasVisited(cell.id) ? .white : .green)
                                .foregroundColor(vm.hasVisited(cell.id) ? .green : .white)
                                .disabled(cell.id.isEmpty)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFriend = cell
                            }
                        }
                    } header: {
                        LimitInfoHeader(title: "フレンド", current: vm.friends.count, limit: 50, description: "最大50人まで登録できます。")
                    }
                }
                .tag(Tab.friend).tabItem { Text("フレンド") }

                // 申請（自分が送った）
                List {
                    Section {
                        ForEach(vm.outgoing) { cell in
                            HStack(spacing: 12) {
                                ProfileCircleAvatar(imageID: cell.imageID, effectID: cell.effectID, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cell.name).font(.headline)
                                    Text("申請中").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("取り下げ") {
                                    targetToWithdraw = cell
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    } header: {
                        LimitInfoHeader(title: "申請数", current: vm.outgoing.count, limit: 20, description: "最大20件まで同時に申請できます。")
                    }
                }
                .tag(Tab.request).tabItem { Text("申請") }

                // 承認（自分に来ている）
                List(vm.incoming) { cell in
                    HStack(spacing: 12) {
                        ProfileCircleAvatar(imageID: cell.imageID, effectID: cell.effectID, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cell.name).font(.headline)
                            Text("承認待ち").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("承認") {
                            Task {
                                await vm.approve(requestFrom: cell.id)
                                await MainActor.run { statusMessage = "フレンド申請を承認しました。" }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("拒否") {
                            Task {
                                await vm.decline(requestFrom: cell.id)
                                await MainActor.run { statusMessage = "フレンド申請を却下しました。" }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .tag(Tab.approval).tabItem { Text("承認") }
            }
            .padding(.top, 20)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded(handleTabSwipe)
            )
            .onChange(of: selection) {
                SoundEffect.play("pageMove", player: &audioPlayer)
            }
            if let friend = selectedFriend {
                Color.black.opacity(0.4).ignoresSafeArea()
                FriendDetailPopupView(friend: friend,
                                      onClose: { selectedFriend = nil },
                                      onDelete: {
                                          selectedFriend = nil
                                          targetToRemove = friend
                                      })
            }
            if let target = targetToRemove {
                Color.black.opacity(0.4).ignoresSafeArea()
                FriendRemovePopupView(name: target.name,
                                       onCancel: { targetToRemove = nil },
                                       onConfirm: {
                                            Task {
                                                await vm.removeFriend(target.id)
                                                await MainActor.run { targetToRemove = nil; statusMessage = "該当のフレンドを削除しました" }
                                            }
                                       })
            }
            if let target = targetToWithdraw {
                Color.black.opacity(0.4).ignoresSafeArea()
                FriendRequestCancelPopupView(name: target.name,
                                             onCancel: { targetToWithdraw = nil },
                                             onConfirm: {
                                                Task {
                                                    await vm.cancelOutgoing(to: target.id)
                                                    await MainActor.run {
                                                        targetToWithdraw = nil
                                                        statusMessage = "フレンド申請を取り下げました。"
                                                    }
                                                }
                                             })
            }
            // 申請タブのみ右下にフレンド申請ボタンを表示
            if selection == .request {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            SoundEffect.play("Button", player: &audioPlayer)
                            uidInput = ""
                            showUIDPopup = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                                .foregroundColor(.white)
                        }
                        .frame(width: 55, height: 55)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
                .zIndex(1)
            }

            // UID入力ポップアップ
            if showUIDPopup {
                Color.black.opacity(0.4).ignoresSafeArea()
                UIDInputPopupView(uid: $uidInput,
                                   myUid: Auth.auth().currentUser?.uid ?? "",
                                   onOK: {
                                       Task { await lookupUserAndShow() }
                                   },
                                   onCancel: { showUIDPopup = false })
                .zIndex(2)
            }

            // フレンド申請確認ポップアップ
            if showFriendRequestPopup, let prof = foundProfile {
                Color.black.opacity(0.4).ignoresSafeArea()
                FriendRequestConfirmPopupView(name: prof.name,
                                              imageID: prof.imageID,
                                              effectID: prof.effectID,
                                              onRequest: {
                                                  Task {
                                                      // UI側事前ガード（pending>=20 または friends>=50 なら即リターン）
                                                      if vm.outgoing.count >= 20 {
                                                          await MainActor.run { statusMessage = "申請数が上限(20)に達しています。"; showFriendRequestPopup = false }
                                                          return
                                                      }
                                                      if vm.friends.count >= 50 {
                                                          await MainActor.run { statusMessage = "フレンド枠が上限(50)です。"; showFriendRequestPopup = false }
                                                          return
                                                      }
                                                      do {
                                                          try await FriendService.request(toUid: prof.id)
                                                          await vm.loadAll()
                                                          await MainActor.run { showFriendRequestPopup = false; statusMessage = "フレンド申請を送信しました。" }
                                                      } catch {
                                                          await MainActor.run { statusMessage = "申請に失敗しました。時間をおいてお試しください。" }
                                                      }
                                                  }
                                              },
                                              onClose: { showFriendRequestPopup = false })
                .zIndex(2)
            }

            // 該当プレイヤーがいなかった場合のポップアップ
            if showNotFoundPopup {
                Color.black.opacity(0.4).ignoresSafeArea()
                NotFoundPopupView(onClose: { showNotFoundPopup = false })
                .zIndex(2)
            }
            if let message = statusMessage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { statusMessage = nil }
                SimpleMessagePopupView(message: message, onClose: { statusMessage = nil })
                .zIndex(2)
            }
            if vm.isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .zIndex(3)
            }

            if showGuide {
                FirstVisitGuideView(
                    title: "フレンド画面",
                    messages: [
                        "フレンドになると、その人のギャラリーへ行ける！"
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
        .task { await vm.loadAll() } // 画面表示時に一括ロード
        .onAppear {
            if !hasSeenGuide {
                DispatchQueue.main.async {
                    withAnimation { showGuide = true }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button {
                    SoundEffect.play("close", player: &audioPlayer)
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding(.trailing, 30)
                }
            }
        }
        .navigationDestination(for: String.self) { uid in
            OtherGalleryMapGameView(targetUserUid: uid)
        }
    }
    }
}

private struct LimitInfoHeader: View {
    var title: String
    var current: Int
    var limit: Int
    var description: String

    private var isFull: Bool { current >= limit }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(current)/\(limit)")
                    .font(.headline)
                    .foregroundColor(isFull ? .red : .primary)
            }
            ProgressView(value: Double(current), total: Double(limit))
                .tint(isFull ? .red : .green)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
        .padding(.vertical, 6)
    }
}

private struct FriendRemovePopupView: View {
    var name: String
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
                        Text("\(name)をフレンドから削除しますか？")
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

private struct FriendRequestCancelPopupView: View {
    var name: String
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
                        Text("\(name)へのフレンド申請を取り下げますか？")
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

private struct FriendDetailPopupView: View {
    var friend: FriendCellVM
    var onClose: () -> Void
    var onDelete: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            // 画面全体の半透明背景：どこでもタップで閉じる
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            // ポップアップ本体（削除ボタン以外はヒットテスト無効で背景に透過）
            VStack {
                Spacer()
                Group {
                    ProfileCircleAvatar(imageID: friend.imageID, effectID: friend.effectID, size: 150)
                    Text(friend.name).font(.title2).padding(.top, 16)
                    Text("Lv.\(friend.level)").font(.headline).padding(.top, 4)
                }
                .allowsHitTesting(false) // （背景にタップを通す）

                // 削除ボタンだけはタップ可能
                Button("削除") {
                    SoundEffect.play("Button", player: &audioPlayer)
                    onDelete()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.top, 24)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: popupWidth)
        }
    }
}

extension FriendHubView {
    private func handleTabSwipe(_ value: DragGesture.Value) {
        guard abs(value.translation.width) > abs(value.translation.height),
              abs(value.translation.width) > 40 else { return }
        if value.translation.width < 0 {
            shiftSelection(1)
        } else {
            shiftSelection(-1)
        }
    }

    private func shiftSelection(_ offset: Int) {
        guard let currentIndex = Tab.allCases.firstIndex(of: selection) else { return }
        let newIndex = currentIndex + offset
        guard Tab.allCases.indices.contains(newIndex) else { return }
        selection = Tab.allCases[newIndex]
    }

    private func lookupUserAndShow() async {
        let target = uidInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        await MainActor.run {
            showUIDPopup = false
            vm.isLoading = true
        }
        guard let cell = await lookupUser(uid: target) else {
            await MainActor.run {
                showNotFoundPopup = true
                vm.isLoading = false
            }
            return
        }
        await MainActor.run {
            foundProfile = cell
            showFriendRequestPopup = true
            vm.isLoading = false
        }
    }

    private func lookupUser(uid: String) async -> FriendCellVM? {
        let db = Firestore.firestore()
        do {
            let userSnap = try await db.document("users/\(uid)").getDocument()
            guard userSnap.exists,
                  let user = try? userSnap.data(as: UserDoc.self) else { return nil }
            let pubSnap = try? await db.document("publicProfiles/\(uid)").getDocument()
            let pub = try? pubSnap?.data(as: PublicProfileDoc.self)
            let g = pub?.gallerySummary
            let xp = user.xp ?? 0
            let fp = user.friendPoints
            return FriendCellVM(id: uid,
                                name: user.username ?? "名無し",
                                xp: xp,
                                friendPoints: fp,
                                imageID: g?.galleryImageID ?? "e01_0%",
                                effectID: g?.galleryEffectID ?? "MyGalleryGE01")
        } catch {
            return nil
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

    private func sendFriendRequest(to receiverUid: String) async throws {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        await MainActor.run { vm.isLoading = true }
        if await isFriend(receiverUid) {
            await MainActor.run { vm.isLoading = false }
            return
        }
        let db = Firestore.firestore()
        let outgoing = try await db.collection("friendRequests")
            .whereField("fromUid", isEqualTo: myUid)
            .whereField("toUid", isEqualTo: receiverUid)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        if !outgoing.documents.isEmpty {
            await MainActor.run { vm.isLoading = false }
            return
        }
        let incoming = try await db.collection("friendRequests")
            .whereField("fromUid", isEqualTo: receiverUid)
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        if !incoming.documents.isEmpty {
            await MainActor.run { vm.isLoading = false }
            return
        }
        try await db.collection("friendRequests").addDocument(data: [
            "fromUid": myUid,
            "toUid": receiverUid,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ])
        await MainActor.run { vm.isLoading = false }
    }
}

// MARK: - ポップアップビュー

private struct UIDInputPopupView: View {
    @Binding var uid: String
    let myUid: String
    var onOK: () -> Void
    var onCancel: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack(spacing: 16) {
                        Spacer()

                        Text("友達のuidを入力して、OKを押してください")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        HStack {
                            Text("自分のuid: \(myUid)")
                                .font(.caption)
                                .lineLimit(2)
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                UIPasteboard.general.string = myUid
                            } label: {
                                Label("コピー", systemImage: "doc.on.doc")
                                    .labelStyle(.titleAndIcon)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("申請相手のuid").font(.caption)
                            TextField("", text: $uid)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: popupWidth - 80)
                        }

                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onCancel()
                            } label: {
                                Image("Cancel Button")
                                    .resizable().renderingMode(.original)
                                    .scaledToFit().frame(width: 150, height: 55)
                            }
                            Button {
                                SoundEffect.play("Button", player: &audioPlayer)
                                onOK()
                            } label: {
                                Image("OK Button")
                                    .resizable().renderingMode(.original)
                                    .scaledToFit().frame(width: 150, height: 55)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                }
        }
    }
}

private struct FriendRequestConfirmPopupView: View {
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

private struct NotFoundPopupView: View {
    var onClose: () -> Void
    @State private var audioPlayer: AVAudioPlayer? = nil
    private var popupWidth: CGFloat { min(UIScreen.main.bounds.width - 20, 420) }

    var body: some View {
        ZStack {
            Image("pop-up window")
                .resizable()
                .scaledToFit()
                .frame(width: popupWidth)
                .overlay {
                    VStack(spacing: 24) {
                        Text("該当のプレイヤーが見つかりませんでした。")
                            .font(.headline).multilineTextAlignment(.center)
                        Button {
                            SoundEffect.play("Button", player: &audioPlayer)
                            onClose()
                        } label: {
                            Image("OK Button")
                                .resizable().renderingMode(.original)
                                .scaledToFit().frame(width: 120, height: 44)
                        }
                        .padding(.bottom, 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                }
        }
    }
}
