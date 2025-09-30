import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

struct NameOnboardingGate: View {
    @ObservedObject var listeners: FirestoreListeners

    // 起動直後にFirestoreがまだ読めていなくても再表示しないためのローカルフラグ
    @AppStorage("didCompleteNameOnboarding") private var didCompleteNameOnboarding = false

    @State private var isPresented = false
    @State private var name: String = ""
    @State private var error: String?

    var body: some View {
        EmptyView()
            .fullScreenCover(isPresented: $isPresented) {
                VStack(spacing: 16) {
                    Text("あなたの名前を決めよう").font(.title2).bold()

                    TextField("プレイヤー名", text: $name)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit { saveName() }

                    if let error {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }

                    Button("決定") { saveName() }
                        .buttonStyle(.borderedProminent)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .interactiveDismissDisabled(true) // スワイプ誤閉じ→再出現を防ぐ
            }
            .onAppear {
                if listeners.user != nil {
                    computePresentation()
                }
            }
            .onReceive(listeners.$user) { _ in computePresentation() }
    }

    private func computePresentation() {
        // Firestore未ロード時のチラ付きを避ける
        if didCompleteNameOnboarding { isPresented = false; return }

        guard let user = listeners.user else {
            isPresented = false
            return
        }

        let current = (user.username ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            isPresented = true
            return
        }

        name = current
        didCompleteNameOnboarding = true
        isPresented = false
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { error = "名前を入力してください"; return }
        guard trimmed.count <= 7 else { error = "7文字以内でお願いします"; return }
        guard let uid = Auth.auth().currentUser?.uid else {
            error = "ログイン状態を確認できません"; return
        }

        error = nil

        Task {
            do {
                let docRef = Firestore.firestore().document(FSPath.user(uid))
                try await docRef.setData(["username": trimmed], merge: true)

                let snapshot = try await docRef.getDocument()
                let fetched = (snapshot.data()?["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                await MainActor.run {
                    name = fetched.isEmpty ? trimmed : fetched
                    didCompleteNameOnboarding = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    isPresented = false

                    if var currentUser = listeners.user {
                        currentUser.username = name
                        listeners.user = currentUser
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "保存に失敗しました。もう一度お試しください。"
                }
                print("username save error:", error)
            }
        }
    }
}
