import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Firebaseの初期化と共通インスタンスを管理するクラス
class FirebaseManager: ObservableObject {
    let auth: Auth
    let firestore: Firestore

    init() {
        // Firebaseを初期化
        FirebaseApp.configure()
        // 各サービスのインスタンスを保持
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
    }
}
