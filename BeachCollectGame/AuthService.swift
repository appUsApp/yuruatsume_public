import Foundation
import FirebaseAuth

/// Service responsible for handling user authentication.
/// Currently only supports anonymous sign-in and keeps track of the user's UID.
class AuthService: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = AuthService()

    /// Published UID of the current user. `nil` if no user is signed in.
    @Published var uid: String?

    private init() {
        // If a user is already signed in, keep its UID.
        self.uid = Auth.auth().currentUser?.uid
    }

    /// Signs in anonymously if there is no current user.
    /// Upon success, the `uid` property will be updated on the main thread.
    func signInAnonymouslyIfNeeded() {
        if let currentUser = Auth.auth().currentUser {
            // Already signed in, just publish the existing UID
            let uid = currentUser.uid
            DispatchQueue.main.async { [weak self] in
                self?.uid = uid
                Task { await FirestoreBootstrap.run(uid: uid) }
            }
            return
        }

        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("Anonymous sign-in failed: \(error.localizedDescription)")
                return
            }
            if let user = result?.user {
                let uid = user.uid
                DispatchQueue.main.async {
                    self?.uid = uid
                    Task { await FirestoreBootstrap.run(uid: uid) }
                }
            }
        }
    }
}
