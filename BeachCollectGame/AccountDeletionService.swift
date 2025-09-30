import Foundation
import SwiftData
import FirebaseAuth
import FirebaseFirestore

enum AccountDeletionError: LocalizedError {
    case noCurrentUser

    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "現在のアカウント情報が見つかりません。"
        }
    }
}

struct AccountDeletionService {
    func deleteAccount(uid: String, context: ModelContext) async throws {
        try await deleteRemoteData(uid: uid)
        try await deleteAuthUser()
        try await MainActor.run {
            try LocalDataResetter.reset(context: context)
        }
        await CurrencyEarningsBuffer.shared.reset()
        clearUserDefaults()
    }

    private func deleteRemoteData(uid: String) async throws {
        let docPaths = [
            FSPath.user(uid),
            FSPath.publicProfile(uid),
            FSPath.galleryConfig(uid),
            FSPath.ownership(uid)
        ]

        for path in docPaths {
            do {
                try await Firestore.firestore().document(path).delete()
            } catch {
                let nsError = error as NSError
                if nsError.domain == FirestoreErrorDomain,
                   let code = FirestoreErrorCode.Code(rawValue: nsError.code),
                   code == .notFound {
                    continue
                }
                throw error
            }
        }
    }

    private func deleteAuthUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AccountDeletionError.noCurrentUser
        }
        try await user.delete()
        try? Auth.auth().signOut()
    }

    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        defaults.synchronize()
    }
}

private enum LocalDataResetter {
    static func reset(context: ModelContext) throws {
        try deleteAll(GameItem.self, in: context)
        try deleteAll(MonsterRecord.self, in: context)
        try deleteAll(OwnedGalleryEffect.self, in: context)
        try deleteAll(OwnedBackground.self, in: context)
        try deleteAll(OwnedBackgroundEffect.self, in: context)
        try deleteAll(OwnedMapItem.self, in: context)
        try deleteAll(OwnedGalleryImage.self, in: context)
        try deleteAll(OwnedBGM.self, in: context)
        try deleteAll(GalleryConfig.self, in: context)
        try deleteAll(MissionState.self, in: context)
        try deleteAll(MissionMeta.self, in: context)
        try deleteAll(ToolCountState.self, in: context)
        try context.save()

        seedInitialGalleryImages(context: context)
        ensureDefaultGalleryConfig(context: context)
        initializeItemsIfNeeded(context: context)
        initializeMonstersIfNeeded(context: context)
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        let fetch = FetchDescriptor<T>()
        let results = try context.fetch(fetch)
        for model in results {
            context.delete(model)
        }
    }

    private static func seedInitialGalleryImages(context: ModelContext) {
        for page in baseGalleryPages {
            let id = "\(page)_0%"
            let fetch = FetchDescriptor<OwnedGalleryImage>(predicate: #Predicate { $0.id == id })
            if ((try? context.fetch(fetch).isEmpty) ?? true) {
                context.insert(OwnedGalleryImage(id: id))
            }
        }
        try? context.save()
    }

    private static func ensureDefaultGalleryConfig(context: ModelContext) {
        let fetch = FetchDescriptor<GalleryConfig>()
        let hasConfig = ((try? context.fetch(fetch).isEmpty) ?? true) == false
        if !hasConfig {
            context.insert(GalleryConfig())
            try? context.save()
        }
    }
}
