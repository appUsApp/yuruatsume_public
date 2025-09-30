import Foundation
import Combine
import FirebaseFirestore

final class FirestoreListeners: ObservableObject {
    @Published var user: UserDoc?
    @Published var publicProfile: PublicProfileDoc?
    @Published var galleryConfig: GalleryConfigDoc?

    private var userListener: ListenerRegistration?
    private var publicListener: ListenerRegistration?
    private var galleryListener: ListenerRegistration?

    func listenUser(uid: String) {
        stopUser()
        userListener = Firestore.firestore()
            .document(FSPath.user(uid))
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err = err { print("user listen err:", err); return }
                guard let snap, snap.exists else { self.user = nil; return }
                do { self.user = try snap.data(as: UserDoc.self) }
                catch { print("user decode err:", error) }
            }
    }

    func listenPublicProfile(uid: String) {
        stopPublic()
        publicListener = Firestore.firestore()
            .document(FSPath.publicProfile(uid))
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err = err { print("public listen err:", err); return }
                guard let snap, snap.exists else { self.publicProfile = nil; return }
                do { self.publicProfile = try snap.data(as: PublicProfileDoc.self) }
                catch { print("public decode err:", error) }
            }
    }

    func listenGalleryConfig(uid: String) {
        stopGallery()
        galleryListener = Firestore.firestore()
            .document(FSPath.galleryConfig(uid))
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err = err { print("gallery listen err:", err); return }
                guard let snap, snap.exists else { self.galleryConfig = nil; return }
                do { self.galleryConfig = try snap.data(as: GalleryConfigDoc.self) }
                catch { print("gallery decode err:", error) }
            }
    }

    func stopAll() { stopUser(); stopPublic(); stopGallery() }
    func stopUser() { userListener?.remove(); userListener = nil }
    func stopPublic() { publicListener?.remove(); publicListener = nil }
    func stopGallery() { galleryListener?.remove(); galleryListener = nil }
}
