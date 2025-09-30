import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    private let db = Firestore.firestore()

    func fetch<T: Decodable>(_ path: String) async throws -> T? {
        let doc = try await db.document(path).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: T.self)
    }

    func upsert<T: Encodable>(_ path: String, _ value: T) async throws {
        try db.document(path).setData(from: value, merge: true)
    }

    func exists(_ path: String) async throws -> Bool {
        let doc = try await db.document(path).getDocument()
        return doc.exists
    }
}

enum FSPath {
    static func user(_ uid: String) -> String { "users/\(uid)" }
    static func publicProfile(_ uid: String) -> String { "publicProfiles/\(uid)" }
    static func galleryConfig(_ uid: String) -> String { "galleryConfigs/\(uid)" }
    static func ownership(_ uid: String) -> String { "ownership/\(uid)" }
}
